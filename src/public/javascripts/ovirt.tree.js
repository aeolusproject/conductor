function processTree (){
  $("#nav_tree_form").ajaxSubmit({
    url: tree_url,
    type: "POST",
    dataType: "json",
    success: function(response){
      // First, remove any deleted items from the tree
      $.each(response.deleted, function(name, value){
          //FIXME: special case for other peoples smart pools
          //come up with better way or split out somewhere.

          //check if the li is the only one.  If so, remove its container as well
          if ($('#' + value.id).parent("li").siblings().size() === 0 ) {
            if($('#' + value.id).is(':visible')) {
              $('#' + value.id).parent("li").parent("ul").siblings("div").click();
            }
            $('#' + value.id).parent("li").parent("ul").remove();
          } else {
            if($('#' + value.id).is(':visible')) {
                $('#' + value.id).parent()
                .siblings('li:first')
                .children('div')
                .click();
              }
          }
          $('#' + value.id).parent().remove();
      });

      if(processRecursive) {
        $("#nav_tree").html(recursiveTreeTempl.process({"pools" : response.pools}));
        processRecursive = false;
      } else {
          // Loop through the items and decide if we need updated/new html for each item.
          processChildren(response.pools, treeItemTempl);
      }
    }
  });
}

function processChildren(list, templateObj){
/*  TODO: In future, we may need an additional state here of 'moved' which deletes
 *  the item where it was in the tree and adds it to its new parent.
*/
  $.each(list, function(n,data){
    var updatedNode;
    if(data.state === 'changed'){
      $('input[value^=' + data.id + '-]').attr('value', data.id + '-' + data.name);
      $('#' + data.id).html(data.name);
    } else if(data.state === 'new') {
        /* If the elem with id matching the parent id has a sibling that is a ul,
         * we should append the result of processing the template to the existing
         * sublist.  Otherwise, we need to add a new sublist and add it there.
        */
       var result  = templateObj.process(data);
       if ($('#' + data.parent_id).siblings('ul').size() > 0) {
         $('#' + data.parent_id).siblings('ul').append(result);
       } else {
         $('#' + data.parent_id).parent().append('<ul>' + result + '</ul>');
         $('#' + data.parent_id).siblings('span').addClass('expanded');
       }
    }
    if (data.children) {
      processChildren(data.children, templateObj);
    }
  });
}

(function($){
	// widget prototype. Everything here is public
	var Tree  = {
                getTemplate: function () { return this.getData('template'); },
		setTemplate: function (x) {
                    this.setData('template', TrimPath.parseDOMTemplate(this.getData('template')));
		},
		init: function() {
                    var self = this, o = this.options;
                    this.setTemplate(this.getTemplate());
                    this.populate();
                    this.element
                    .bind('click', function(event){
                        self.clickHandler(event, self);
                        if(self.getData('toggle') === 'toggle') {
                          self.toggle(event, this);
                        } else {
                          self.element.triggerHandler('toggle',[event,this],self.getData('toggle'));
                        }
                    });
                    o.selectedNodes !== undefined? this.openToSelected() :o.selectedNodes=[];
                    o.channel !== undefined? this.subscribe(o.channel): o.channel = '';
                    if (o.cacheContent === true) this.buildLookup();
                },
                populate: function() {
                    var contentWithId = this.getData('content');
                    contentWithId.id = this.element.get(0).id;
                    this.element.html(this.getTemplate().process(contentWithId));
                },
                buildLookup: function() {
                    this.setData('lookupList', this.walkTree(this.getData('content').pools, [], this));
                },
                walkTree: function(list, lookup, self) {
                    $.each(list, function(n,obj){
                        lookup.push(obj);
                        if (obj.children && obj.children.length > 0) self.walkTree(obj.children, lookup, self);
                    });
                    return lookup;
                },
                subscribe: function subscribe(channel) {
                    var self = this;
                    this.element.bind(channel, function(e,data){self.refresh(e,data);});
                },
                toggle: function(e, elem) {
                    if ($(e.target).is('span.hitarea')){
                      $(e.target)
                      .toggleClass('expanded')
                      .toggleClass('expandable')
                      .siblings('ul').slideToggle("normal");
                      if ($(e.target).hasClass('expanded')) {
                        this.setSelectedNode(this.chop(e.target), true);
                      } else {
                          this.setSelectedNode(this.chop(e.target), false);
                      }
                    }
                },
                chop: function(elem) {
                    var id = $(elem).siblings('div').get(0).id;
                    return id.substring(id.indexOf('-') +1);
                },
                clickHandler: function(e,elem) { //TODO: make this a default impl if needed.
                    this.options.clickHandler !== undefined? this.element.triggerHandler('clickHandler',[e,this],this.getData('clickHandler')): null;
                    if ($(e.target).is('div') && $(e.target).parent().is('li')){}
                },
                setSelectedNode: function(id, isOpen) {
                    if (isOpen) {
                        if($.inArray(id,this.getData('selectedNodes')) == -1){
                          this.setData(this.getData('selectedNodes').push(id));
                        }
                    } else {
                        if($.inArray(id,this.getData('selectedNodes')) != -1){
                          this.setData(this.getData('selectedNodes').splice(this.getData('selectedNodes').indexOf(id),1));
                        }
                    }
                },
                openToSelected: function() {
                    for (var i = 0; i < this.getData('selectedNodes').length; i++){
                      this.toggle($.event.fix({type: 'toggle',
                                              target: this.element.find('#' +this.element.get(0).id + '-' + this.getData('selectedNodes')[i]).siblings('span').get(0)})
                                  , this);
                    }
                },
                refresh: function(e, list) {
                    //NOTE: The widget expects the convention used elsewhere of {blah}-{ui_object}
                    //(where {blah} is the id of the container element, see above for an example soon),
                    //since there may be 2 items with the same db id.
                    var self = this;
                    list = $.makeArray(list);
                    $.each(list, function(n,data){
                      switch(data.state) {
                          case 'deleted': {
                            self._delete(data);
                            break;
                          }
                          case 'changed': {
                            self._update(data);
                            break;
                          }
                          default: {
                            self._add(data);
                            break;
                          }
                      }
                    });
                    self.options.refresh !== undefined? self.element.triggerHandler('refresh',[e,list],self.getData('refresh')): null;
                },
                //methods meant to be called internally by widget
                _add: function(data){
                  var myLookupList = this.getData('lookupList');
                    if (data.ui_parent !==null) {
                      var matchedItems = $.grep(myLookupList,function(value) {return value.ui_object == data.ui_parent;});
                      var self = this;
                      $.each(matchedItems, function(n,obj){
                        var existingObj = [];
                        if(obj.children && obj.children.length >0) {
                          existingObj = $.grep(obj.children,function(value) {return value.ui_object == data.ui_object;});
                        }
                        if (existingObj.length === 0){
                            obj.children.push(data);
                            myLookupList.push(data);
                            self._addDomElem(data);
                        } else {}
                      });
                    } else {myLookupList.push(data);}
                },
                _delete: function(data){}, //TODO: implement
                _update: function(data) {}, //TODO: implement
                _addDomElem: function(data) {
                  var dataToInsert = this.getTemplate().process({"pools":[data], "id":this.element.get(0).id});
                  if (data.ui_parent) {
                    var searchString = '#' + this.element.get(0).id + '-' + data.ui_parent;
                    var parentElem = this.element.find(searchString).siblings('ul');
                    if (parentElem.size() === 0) {
                        this.element.find(searchString).parent().append('<ul>' + dataToInsert + '</ul>');
                        this.element.find(searchString).siblings('span').addClass('expanded');
                    } else {
                      parentElem.append(dataToInsert);
                    }
                  } else {
                      this.element.append(dataToInsert);
                  }
                },
                _deleteDomElem: function(data) {}, //TODO: implement
                _updateDomElem: function(data) {} //TODO: implement
	};
	$.yi = $.yi || {}; // create the namespace
	$.widget("yi.tree", Tree);
	$.yi.tree.defaults = {
            template: 'tree_template',
            toggle: 'toggle',
            clickHandler: 'clickHandler',
            cacheContent: true
	};
})(jQuery);
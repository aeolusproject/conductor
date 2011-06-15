/**
*	@name							Show Password
*	@descripton
*	@version						1.2
*	@requires						Jquery 1.2.6+
*
*	@author							Jan Jarfalk
*	@author-email					jan.jarfalk@unwrongest.com
*	@author-website					http://www.unwrongest.com
*
*	@special-thanks					Michel Gratton
*
*	@licens							MIT License - http://www.opensource.org/licenses/mit-license.php
*/
 (function($) {
    $.fn.extend({
        showPassword: function(options, callback) {
            return this.each(function() {

                var $input = $(this),
                callbackArguments = {
                    'input': $input
                },
                $checkbox = $(options.checkbox);


                // Create clone
                var $clone = cloneElement($input);

                // Add clone to callback arguments
                callbackArguments.clone = $clone;

                $clone.insertAfter($input);

                function cloneElement(element) {

                    var $element = $(element);

                    $clone = $("<input />");

                    // Name added for JQuery Validation compatibility
                    // Element name is required to avoid script warning.
                    $clone.attr({
                        'type': 'text',
                        'class': $input.attr('class'),
                        'style': $input.attr('style'),
                        'size': $input.attr('size'),
                        'name': '_' + $input.attr('name'),
                        'tabindex': $input.attr('tabindex')
                    });

                    return $clone;
                };

                var update = function(a, b) {
                    b.val(a.val());
                };

                var setState = function() {
                    if ($checkbox.is(':checked')) {
                        update($input, $clone);
                        $clone.show();
                        $input.hide();
                    } else {
                        update($clone, $input);
                        $clone.hide();
                        $input.show();
                    }
                };

                $checkbox.bind('click',
                function() {
                    setState();
                });

                $input.bind('keyup',
                function() {
                    update($input, $clone)
                });

                $clone.bind('keyup',
                function() {
                    update($clone, $input);

                    // Added for JQuery Validation compatibility
                    // This will trigger validation if it's ON for keyup event
                    $input.trigger('keyup');

                });

                // Added for JQuery Validation compatibility
                // This will trigger validation if it's ON for blur event
                $clone.bind('blur',
                function() {
                    $input.trigger('focusout');
                });

                setState();

                if (callback) {
                    callback(callbackArguments);
                }

            });
        }
    });
})(jQuery);

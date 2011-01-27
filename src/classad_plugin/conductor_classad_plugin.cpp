#include <stdio.h>

#include <iostream>
#include <sstream>

#include "classad/classad_distribution.h"
#include "classad/fnCall.h"

#include <rest/rest-proxy.h>
#include <rest/rest-xml-parser.h>

using namespace std;
#ifdef WANT_CLASSAD_NAMESPACE
using namespace classad;
#endif

#define print_value(fp, val) _print_value(fp, val, #val)
#define print_type(fp, val) _print_type(fp, val, #val)

static void _print_type(FILE *fp, Value val, const char *name)
{
  fprintf(fp, "%s type is: ", name);

  switch(val.GetType()) {
  case Value::NULL_VALUE:
    fprintf(fp, "NULL");
    break;
  case Value::ERROR_VALUE:
    fprintf(fp, "Error");
    break;
  case Value::UNDEFINED_VALUE:
    fprintf(fp, "Undefined");
    break;
  case Value::BOOLEAN_VALUE:
    fprintf(fp, "Boolean");
    break;
  case Value::INTEGER_VALUE:
    fprintf(fp, "Integer");
    break;
  case Value::REAL_VALUE:
    fprintf(fp, "Real");
    break;
  case Value::LIST_VALUE:
    fprintf(fp, "List");
    break;
  case Value::CLASSAD_VALUE:
    fprintf(fp, "Classad");
    break;
  case Value::RELATIVE_TIME_VALUE:
    fprintf(fp, "RelativeTime");
    break;
  case Value::ABSOLUTE_TIME_VALUE:
    fprintf(fp, "AbsoluteTime");
    break;
  case Value::STRING_VALUE:
    fprintf(fp, "String");
    break;
  }

  fprintf(fp, "\n");
}

static void _print_value(FILE *fp, Value val, const char *name)
{
    /* AFAICT the only way to get at the string in a 'Value' object is to use
     * the C++ stream operator <<,  so we set up a stringstream and write
     * stuff we want into that..
     */
    std::stringstream sstr;

    sstr << name << " is " << val;
    fprintf(fp, "%s\n", sstr.str().c_str());
}

static RestXmlNode *
get_xml (RestProxyCall *call)
{
  RestXmlParser *parser;
  RestXmlNode *root;
  GError *error = NULL;

  parser = rest_xml_parser_new ();

  root = rest_xml_parser_parse_from_data (parser,
                                          rest_proxy_call_get_payload (call),
                                          rest_proxy_call_get_payload_length (call));

  g_object_unref (call);
  g_object_unref (parser);

  return root;
}


/*
 * Perform our quota check against the Aeolus Conductor database.
 * This function expects:
 *
 * - Instance executable name as handed to condor so that we can map to the
 *   instance found in the database.
 * - The username
 * - The provider url so we can map back to the provider.
 * - The realm key so we know what realm this is in.
 *
 * ... at least for now.  Need to better analyze what is required to do all
 * the quota matching but that's the idea.
 */
bool
conductor_quota_check(const char *name, const ArgumentList &arglist,
		      EvalState &state, Value &result)
{
    Value instance_id;
    Value account_id;
    FILE *fp;
    bool val = false;
    RestProxy *proxy;
    RestProxyCall *call;
    RestXmlNode *root;
    std::stringstream rest_call;
    GError *err = NULL;

    g_thread_init (NULL);
    g_type_init ();

    result.SetBooleanValue(false);

    fp = fopen(LOGFILE, "a");

    if (arglist.size() != 2) {
      result.SetErrorValue();
      fprintf(fp, "Expected 2 arguments, saw %z\n", arglist.size());
      goto do_ret;
    }

    if (!arglist[0]->Evaluate(state, instance_id)) {
      result.SetErrorValue();
      fprintf(fp, "Could not evaluate argument 0 to instance id\n");
      goto do_ret;
    }
    if (!arglist[1]->Evaluate(state, account_id)) {
      result.SetErrorValue();
      fprintf(fp, "Could not evaluate argument 1 to account id\n");
      goto do_ret;
    }

    print_type(fp, instance_id);
    print_value(fp, instance_id);
    if (instance_id.GetType() != Value::INTEGER_VALUE) {
      result.SetErrorValue();
      fprintf(fp, "Instance id type was not an integer\n");
      goto do_ret;
    }

    print_type(fp, account_id);
    print_value(fp, account_id);
    if (account_id.GetType() != Value::STRING_VALUE) {
      result.SetErrorValue();
      fprintf(fp, "Account ID type was not a string\n");
      goto do_ret;
    }

    rest_call << "resources/instances/" << instance_id << "/can_start/" << account_id;

    // Call rest API to get answer on quota..
    proxy = rest_proxy_new ("http://localhost:3000/deltacloud", FALSE);
    call = rest_proxy_new_call (proxy);
    rest_proxy_call_set_function (call, rest_call.str().c_str());

    fprintf(fp, "Calling REST API with %s\n", rest_call.str().c_str());
    rest_proxy_call_sync (call, &err);

    if (err != NULL) {
        fprintf (fp, "Error calling REST API: %s\n", err->message);
    } else {
        root = get_xml (call);
        if (root) {
            RestXmlNode *node;
            gchar *value;

            node = rest_xml_node_find (root, "value");
            value = node->content;

            fprintf (fp, "return value is %s\n", value);
            if (strncmp(value, "true", 4) == 0) {
                result.SetBooleanValue(true);
                val = true;
            }
        }
    }

    g_object_unref (proxy);

 do_ret:
    fclose(fp);

    return val;
}

/*
 * Struct containing the names of the functions provided here and a pointer
 * to the function that implements them.  Third arg is an int flags that appears
 * to be unused.
 *
 * This is found in fnCall.h
 */
static ClassAdFunctionMapping classad_functions[] =
{
    { "conductor_quota_check", (void *) conductor_quota_check, 0 },
    { "", NULL, 0 }
};

/*
 * This is the 'Init' function that is called after the library is dlopen()'d.
 * This just returns the struct defined above.
 *
 */
extern "C"
{
    ClassAdFunctionMapping *
    Init(void) {
        return classad_functions;
    }
}


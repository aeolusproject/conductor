#include <ruby.h>
#include <stdio.h>

#include <iostream>
#include <sstream>

#include "classad/classad_distribution.h"
#include "classad/fnCall.h"

using namespace std;
#ifdef WANT_CLASSAD_NAMESPACE
using namespace classad;
#endif

void print_value(FILE *fp, Value val, const char *name)
{
    /* AFAICT the only way to get at the string in a 'Value' object is to use
     * the C++ stream operator <<,  so we set up a stringstream and write
     * stuff we want into that..
     */
    std::stringstream sstr;

    sstr << name << " is " << val;
    fprintf(fp, "%s\n", sstr.str().c_str());
}

/*
 * Perform our quota check against the deltacloud aggregator database.
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
deltacloud_quota_check(const char *name, const ArgumentList &arglist,
		       EvalState &state, Value &result)
{
    Value instance_key;
    Value account_id;
    FILE *fp;
    char msg[1024];
    VALUE res;
    bool val = false;
    char *ruby_string;
    std::stringstream method_args;
    static int ruby_initialized = 0;

    result.SetBooleanValue(false);

    fp = fopen(LOGFILE, "a");

    if (arglist.size() != 2) {
      result.SetErrorValue();
      fprintf(fp, "Expected 2 arguments, saw %d\n", arglist.size());
      goto do_ret;
    }

    if (!arglist[0]->Evaluate(state, instance_key)) {
      result.SetErrorValue();
      fprintf(fp, "Could not evaluate argument 0 to instance key\n");
      goto do_ret;
    }
    if (!arglist[1]->Evaluate(state, account_id)) {
      result.SetErrorValue();
      fprintf(fp, "Could not evaluate argument 1 to account_id\n");
      goto do_ret;
    }

    if (instance_key.GetType() != Value::STRING_VALUE) {
      result.SetErrorValue();
      fprintf(fp, "Instance type was not a string\n");
      goto do_ret;
    }
    //print_value(fp, instance_key, "instance_key");

    if (account_id.GetType() != Value::STRING_VALUE) {
      result.SetErrorValue();
      fprintf(fp, "Account ID type was not a string\n");
      goto do_ret;
    }
    //print_value(fp, account_id, "account_id");

    if (!ruby_initialized) {
        ruby_init();
        ruby_init_loadpath();
    }

    method_args << "'" << instance_key << "', " << account_id;

    asprintf(&ruby_string,
             "$: << '%s/classad_plugin'\n"
             "$: << '%s/dutils'\n"
             "$: << '%s/models'\n"
             "begin\n"
             "   require 'classad_plugin.rb'\n"
             "   classad_plugin(%s)\n"
             "rescue Exception => ex\n"
             "   f = File.new('%s', 'a')\n"
             "   f.write \"Error running classad plugin: #{ex.message}\"\n"
             "   f.write ex.backtrace\n"
             "   f.close\n"
             "   false\n"
             "end\n",
             DELTACLOUD_INSTALL_DIR,
             DELTACLOUD_INSTALL_DIR,
             DELTACLOUD_INSTALL_DIR,
             method_args.str().c_str(),
             LOGFILE);

    fflush(fp);

    res = rb_eval_string(ruby_string);
    free(ruby_string);

    if (res == Qtrue) {
        result.SetBooleanValue(true);
        val = true;
    } else {
        fprintf(fp, "Returned result from ruby code was %s\n", (res == Qtrue) ? "true" : "false");
    }

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
    { "deltacloud_quota_check", (void *) deltacloud_quota_check, 0 },
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

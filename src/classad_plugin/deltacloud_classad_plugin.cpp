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
    VALUE res;
    bool val = false;
    char *ruby_string;
    std::stringstream method_args;
    int rc;

    result.SetBooleanValue(false);

    fp = fopen(LOGFILE, "a");

    if (arglist.size() != 2) {
      result.SetErrorValue();
      fprintf(fp, "Expected 2 arguments, saw %z\n", arglist.size());
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

    print_type(fp, instance_key);
    print_value(fp, instance_key);
    if (instance_key.GetType() != Value::STRING_VALUE) {
      result.SetErrorValue();
      fprintf(fp, "Instance type was not a string\n");
      goto do_ret;
    }

    print_type(fp, account_id);
    print_value(fp, account_id);
    if (account_id.GetType() != Value::STRING_VALUE) {
      result.SetErrorValue();
      fprintf(fp, "Account ID type was not a string\n");
      goto do_ret;
    }

    ruby_init();
    ruby_init_loadpath();

    method_args << "'" << DELTACLOUD_INSTALL_DIR << "/config/database.yml', '"
		<< instance_key << "', " << account_id;

    rc = asprintf(&ruby_string,
		  "$: << '%s/classad_plugin'\n"
		  "$: << '%s/app/models'\n"
		  "logf = File.new('%s', 'a')\n"
		  "logf.puts \"Loading ruby support file from %s/classad_plugin\"\n"
		  "begin\n"
		  "   require 'classad_plugin.rb'\n"
		  "   ret = classad_plugin(logf, %s)\n"
		  "rescue Exception => ex\n"
		  "   logf.puts \"Error running classad plugin: #{ex.message}\"\n"
		  "   logf.puts ex.backtrace\n"
		  "   ret = false\n"
		  "end\n"
		  "logf.close\n"
		  "ret",
		  DELTACLOUD_INSTALL_DIR,
		  DELTACLOUD_INSTALL_DIR,
		  LOGFILE,
		  DELTACLOUD_INSTALL_DIR,
		  method_args.str().c_str());

    if (rc < 0) {
      fprintf(fp, "Failed to allocate memory for asprintf\n");
      goto do_ret;
    }

    fprintf(fp, "ruby string is %s\n", ruby_string);
    fflush(fp);

    res = rb_eval_string(ruby_string);
    free(ruby_string);

    /* FIXME: I'd like to call ruby_finalize here, but it spews weird errors:
     *
     * Error running classad plugin: wrong argument type Mutex (expected Data)
     */
    //ruby_finalize();

    fprintf(fp, "Returned result from ruby code was %s\n", (res == Qtrue) ? "true" : "false");

    if (res == Qtrue) {
        result.SetBooleanValue(true);
        val = true;
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

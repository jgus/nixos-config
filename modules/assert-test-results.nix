{ testResults, ... }:
{
  # Force evaluation of tests by including in assertions
  config.assertions = [
    {
      assertion = testResults == null;
      message = "Unit tests failed";
    }
  ];
}

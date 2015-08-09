# Contributing

## Submitting an Issue

Issues are tracked on GitHub (TODO).

## Developing a new Feature Provider

1. Create a new class file in `lib/cisco_node_utils/`.
2. Write the class.
3. Add the class to `lib/cisco_node_utils.rb`.
4. Create a new minitest file in `tests/`.
5. Write the minitest. We recommend subclassing the provided `CiscoTestCase`
   class as it provides numerous helper methods.
6. Run the minitest. `ruby test_my_feature.rb -- <NX-OS node IP> <user> <pass>`
7. Once minitest is passing, add the test to `tests/test_all_cisco.rb`.
8. Run rubocop (`rake rubocop`) and fix any failures.
9. Proceed to submit a pull request as described below.

## Submitting a Pull Request

1. Fork the code (https://github.com/cisco/cisco_node_utils/fork) (TODO)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write your code
4. Write minitest cases to cover your new code
5. Verify that minitest passes in full (`ruby tests/test_all_cisco.rb --
   n3k_test.mycompany.com username password`)
6. Verify that rubocop also passes (`rake rubocop`).
7. Commit your changes (`git commit -am 'Add some feature'`)
8. Push to the branch (`git push origin my-new-feature`)
9. Create a new Pull Request

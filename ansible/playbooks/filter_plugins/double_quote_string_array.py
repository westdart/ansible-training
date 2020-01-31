def double_quote_string_array(the_array):
    '''
    Args:
        the_array:  Array of strings
    Returns: String representation of an array, with double quoted strings
    '''
    result = "["
    for element in the_array:
        result = result + "\"" + element + "\","

    if len(the_array) > 0:
        result = result[:-1]

    result = result + "]"

    return result


class FilterModule(object):
    '''
    custom jinja2 filters for working with collections
    '''

    def filters(self):
        return {
            'double_quote_string_array': double_quote_string_array
        }


'''
Testing
'''
import unittest


class TestDoubleQuoteStringArray(unittest.TestCase):
    def test_server_names_array(self):
        strings = [
            "ds-master.openshift.local",
            "ds-node1.openshift.local"
        ]
        result = double_quote_string_array(strings)

        self.assertEqual('["ds-master.openshift.local","ds-node1.openshift.local"]', result)

    def test_server_names_array_one(self):
        strings = [
            "ds-master.openshift.local"
        ]
        result = double_quote_string_array(strings)

        self.assertEqual('["ds-master.openshift.local"]', result)

    def test_server_names_array_zero(self):
        strings = []
        result = double_quote_string_array(strings)

        self.assertEqual('[]', result)


if __name__ == '__main__':
    unittest.main()

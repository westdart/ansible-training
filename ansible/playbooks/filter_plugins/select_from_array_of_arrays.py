import re

def select_from_array_of_arrays(the_array, filter):
    '''
    Args:
        the_array: Array of arrays
        column_value: value required for entry to make it into the output. This can either be a string or an array of
        strings
    Returns: Filtered list of dict objects
    '''
    result = []
    for array in the_array:
        for entry in array:
            if re.search(filter, entry):
                result.append(array)
                break
    return result


class FilterModule(object):
    '''
    custom jinja2 filters for working with collections
    '''

    def filters(self):
        return {
            'select_from_array_of_arrays': select_from_array_of_arrays
        }


'''
Testing
'''
import unittest


class TestSelectFromArrayOfArrays(unittest.TestCase):
    data = [
        [
            "3.8.148.84",
            "t1-master.openshift.local",
            "ip-10-0-2-145.eu-west-2.compute.internal"
        ],
        [
            "3.8.148.85",
            "t2-master.openshift.local",
            "ip-10-0-2-146.eu-west-2.compute.internal"
        ],
        [
            "3.8.238.112",
            "t1-node1.openshift.local",
            "ip-10-0-2-93.eu-west-2.compute.internal"
        ]
    ]

    def test_select_from_array_of_arrays(self):
        result = select_from_array_of_arrays(self.data, 't1-master.openshift.local')

        self.assertEqual(1, len(result))
        self.assertEqual('3.8.148.84', result[0][0])

    def test_select_from_array_of_arrays_miss(self):
        result = select_from_array_of_arrays(self.data, 't2-master.openshift.local')

        self.assertEqual(0, len(result))

    def test_select_from_array_of_arrays_multiple(self):
        result = select_from_array_of_arrays(self.data, '-master\\.')

        self.assertEqual(2, len(result))
        self.assertEqual('3.8.148.84', result[0][0])
        self.assertEqual('3.8.148.85', result[1][0])


if __name__ == '__main__':
    unittest.main()

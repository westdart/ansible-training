def aws_instance_array_to_array_of_dicts(servers, target_list=[]):
    '''
    Args:
        instance_array:  Array of arrays containing server names and instance ids
        target_list: list of server names to get the instance_ids for
    Returns: List with dict representations
    '''
    result = []
    for server in servers:
        if len(server) > 1:
            if target_list is "None" or target_list is None or server[1] in target_list:
                result.append({"name": server[1], "instance_id": server[0]})

    return result


class FilterModule(object):
    '''
    custom jinja2 filters for working with collections
    '''

    def filters(self):
        return {
            'aws_instance_array_to_array_of_dicts': aws_instance_array_to_array_of_dicts
        }


'''
Testing
'''
import unittest


class TestAwsInstanceArrayToArrayOfDicts(unittest.TestCase):
    def test_server_names_array(self):
        servers = [
            [
                "i-05208fc37c3a4f912",
                "jg-master.openshift.local"
            ],
            [
                "i-066ca17661eca0024",
                "jg-node1.openshift.local"
            ],
            [
                "i-0c711266e2e032bd0",
                "ds-master.openshift.local"
            ],
            [
                "i-047fcb12552688a43",
                "docker-registry.openshift.local"
            ],
            [
                "i-0e011d0f67744a544",
                "sb-master.openshift.local"
            ],
            [
                "i-03296bd2f6572066b",
                "ds-node1.openshift.local"
            ],
            [
                "i-0d673d4c99cf2c07f",
                "sb-node1.openshift.local"
            ]
        ]
        result = aws_instance_array_to_array_of_dicts(servers, None)

        self.assertEqual(7, len(result))
        self.assertEqual("jg-master.openshift.local", result[0]["name"])
        self.assertEqual("i-05208fc37c3a4f912", result[0]["instance_id"])
        self.assertEqual("sb-node1.openshift.local", result[6]["name"])
        self.assertEqual("i-0d673d4c99cf2c07f", result[6]["instance_id"])


    def test_server_names_array_empty(self):
        servers = []
        result = aws_instance_array_to_array_of_dicts(servers)

        self.assertEqual(0, len(result))

    def test_server_names_array_with_prefix(self):
        servers = [
            [
                "i-05208fc37c3a4f912",
                "jg-master.openshift.local"
            ],
            [
                "i-066ca17661eca0024",
                "jg-node1.openshift.local"
            ],
            [
                "i-0c711266e2e032bd0",
                "ds-master.openshift.local"
            ],
            [
                "i-047fcb12552688a43",
                "docker-registry.openshift.local"
            ],
            [
                "i-0e011d0f67744a544",
                "sb-master.openshift.local"
            ],
            [
                "i-03296bd2f6572066b",
                "ds-node1.openshift.local"
            ],
            [
                "i-0d673d4c99cf2c07f",
                "sb-node1.openshift.local"
            ]
        ]
        result = aws_instance_array_to_array_of_dicts(servers, ["ds-master.openshift.local", "ds-node1.openshift.local"])

        self.assertEqual(2, len(result))
        self.assertEqual("ds-master.openshift.local", result[0]["name"])
        self.assertEqual("i-0c711266e2e032bd0", result[0]["instance_id"])
        self.assertEqual("ds-node1.openshift.local", result[1]["name"])
        self.assertEqual("i-03296bd2f6572066b", result[1]["instance_id"])

    def test_server_names_array_with_prefix_one_server(self):
        servers = [
            [
                "i-05208fc37c3a4f912",
                "jg-master.openshift.local"
            ],
            [
                "i-066ca17661eca0024",
                "jg-node1.openshift.local"
            ],
            [
                "i-0c711266e2e032bd0",
                "ds-master.openshift.local"
            ],
            [
                "i-047fcb12552688a43",
                "docker-registry.openshift.local"
            ],
            [
                "i-0e011d0f67744a544",
                "sb-master.openshift.local"
            ],
            [
                "i-03296bd2f6572066b",
                "ds-node1.openshift.local"
            ],
            [
                "i-0d673d4c99cf2c07f",
                "sb-node1.openshift.local"
            ]
        ]
        result = aws_instance_array_to_array_of_dicts(servers, ["ds-master.openshift.local"])

        self.assertEqual(1, len(result))
        self.assertEqual("ds-master.openshift.local", result[0]["name"])
        self.assertEqual("i-0c711266e2e032bd0", result[0]["instance_id"])

if __name__ == '__main__':
    unittest.main()

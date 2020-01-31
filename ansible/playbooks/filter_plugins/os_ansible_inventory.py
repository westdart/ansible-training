def next_group_name(group):
    return "-".join(group.split('-')[:-1])


def add_to_group(group, name, server):
    _name = name.replace('-', '_')
    if _name not in group:
        group[_name] = [server]
    else:
        group[_name].append(server)
    return group


def build_groups(servers):
    '''
    Args:
        servers:  Array of server names
    Returns: Array of groups based on '-' separated names
    '''
    groups = {}
    for server in servers:
        group1 = server.split('.')[0]
        add_to_group(groups, group1, server)

        group_name = group1
        while '-' in group_name:
            group_name = next_group_name(group_name)
            add_to_group(groups, group_name, server)

    return groups


def os_ansible_inventory(servers):
    '''
    Args:
        servers:  Array of server names
    Returns: String representation of an 'ini' type ansible inventory
    '''
    groups = build_groups(servers)
    result = ""
    for group in groups:
        result = result + "[" + group + "]\n"
        for server in groups[group]:
            result = result + server + "\n"
        result = result + "\n"

    return result


class FilterModule(object):
    '''
    custom jinja2 filters for working with collections
    '''

    def filters(self):
        return {
            'os_ansible_inventory': os_ansible_inventory
        }


'''
Testing
'''
import unittest


class TestOsAnsibleInventory(unittest.TestCase):
    def test_server_names_array(self):
        servers = [
            "ds-master.openshift.local",
            "ds-node1.openshift.local",
            "sb-master.openshift.local",
            "sb-node1.openshift.local",
            "docker-registry.openshift.local"
        ]
        result = build_groups(servers)

        self.assertEqual(8, len(result))
        self.assertEqual(2, len(result['ds']))
        self.assertEqual(1, len(result['ds_master']))
        self.assertEqual(1, len(result['ds_node1']))
        self.assertEqual(2, len(result['sb']))
        self.assertEqual(1, len(result['sb_master']))
        self.assertEqual(1, len(result['sb_node1']))
        self.assertEqual(1, len(result['docker']))
        self.assertEqual(1, len(result['docker_registry']))

    def test_server_long_name_array(self):
        servers = [
            "this-is-a-long-server-name.openshift.local"
        ]
        result = build_groups(servers)

        self.assertEqual(6, len(result))
        self.assertEqual(1, len(result['this_is_a_long_server_name']))
        self.assertEqual(1, len(result['this_is_a_long_server']))
        self.assertEqual(1, len(result['this_is_a_long']))
        self.assertEqual(1, len(result['this_is_a']))
        self.assertEqual(1, len(result['this_is']))
        self.assertEqual(1, len(result['this']))

if __name__ == '__main__':
    unittest.main()

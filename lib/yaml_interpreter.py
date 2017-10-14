import sys
import yaml

YAML_FILE = sys.argv[1]
KEY = sys.argv[2]
with open(YAML_FILE) as file_obj:
    yaml_dict = yaml.load(file_obj)

print(yaml_dict[KEY])


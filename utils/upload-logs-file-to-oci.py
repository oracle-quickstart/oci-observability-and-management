"""
  # This script is intended to run in your OCI Tenancy,
  # It uploads a file from your OCI CLI into the logging analytics upload service.

  # @param f|file - the path of the file to upload
  # @param s|filename - The name with which the file will be saved in OCI
  # @param l|log-source - The log source to upload the file for
  # @param n|name - The name of the upload instance
"""
import subprocess, json, argparse, sys


# CLI Arguments
argParser = argparse.ArgumentParser()
argParser.add_argument("-f", "--file", help="your file", required=True)
argParser.add_argument("-s", "--filename", help="your filename", required=True)
argParser.add_argument("-l", "--log-source", help="your log source", required=True)
argParser.add_argument("-n", "--name", help="your name", required=True)

args = argParser.parse_args()


# Functions
# Lets the user choose a compartment to use the groups of
def choose_compartment() -> str:

  # Compartment Variables
  compartments = json.loads(
    subprocess.getoutput('oci iam compartment list --all --query "data[].{name:name, id:id}" --access-level ANY --compartment-id-in-subtree true')
  )
  compartments_names = [compartment['name'] for compartment in compartments]

  # List the compartments of the OCI tenancies
  print("Here is the list of your OCI tenancy compartments: ")
  for name in enumerate(compartments_names):
    print(*name, sep='> ')

  # Prompt the user to select a value
  selected_input = input("Please, Choose the index of the compartment you want to upload your files to: ")

  while not (selected_input.isnumeric() and 0 <= int(selected_input) < len(compartments_names)) : # re-prompt if the user selected a different value
    selected_input = input("The compartment selected does not exist, Please choose a valid compartment index: ")

  return compartments[int(selected_input)]


# Get the default namespace label
def get_namespace() -> str:
  namespace = subprocess.getoutput('''oci log-analytics namespace list --compartment-id $(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?contains(\\"id\\",'tenancy')].id | [0]") --query "data.items[].{namespace: \\"namespace-name\\"}[0].namespace" --raw-output''')

  return namespace


# Lets the user choose a compartment to use the groups of
def choose_log_group(settings:dict) -> str:

  response = subprocess.getoutput(f'''oci log-analytics log-group list -c {settings["compartment"]["id"]} --namespace-name {settings["namespace"]} --query "data.items[].{{name: \\"display-name\\", id: id}}"''')

  if response == "Query returned empty result, no output to show.":
    # Create a new log group
    print('You have no log groups in your compartment (Check your region and tenancy again)')
    if not input('Do you want to create a new log group automatically? (y|n): ').lower() in ('y', 'yes'):
      sys.exit("No log Groups created! The script was aborted!")
      return

    return create_log_group(settings)

  # Compartment Variables
  log_groups = json.loads(
    subprocess.getoutput(f'''oci log-analytics log-group list -c {settings["compartment"]["id"]} --namespace-name {settings["namespace"]} --query "data.items[].{{name: \\"display-name\\", id: id}}"''')
  )

  log_groups_names = [log_group['name'] for log_group in log_groups]

  # List the log groups of the OCI tenancies
  print("Here is the list of your OCI tenancy log groups: ")
  for name in enumerate(log_groups_names):
    print(*name, sep='> ')

  # Prompt the user to select a value
  selected_input = input("Please, Choose the index of the log group you want to upload your files to: ")

  while not (selected_input.isnumeric() and 0 <= int(selected_input) < len(log_groups_names)) : # re-prompt if the user selected a different value
    selected_input = input("The log group selected does not exist, Please choose a valid log group index: ")

  return log_groups[int(selected_input)]


# Create a new log group
def create_log_group(settings:dict):
  return json.loads(
    subprocess.getoutput(f'''oci log-analytics log-group create --namespace-name {settings["namespace"]} --display-name "Live Labs Log Group - You can delete it once you are done" --compartment-id {settings["compartment"]["id"]} --query "data.{{name:\\"display-name\\", id:\\"id\\"}}"''')
  )


# Implementation
# The bash command parameters
settings = {
  "compartment": choose_compartment(),
  "namespace": get_namespace()
}

settings["log_group"] = choose_log_group(settings)

# OCI command script
print(
  subprocess.getoutput(f'''oci log-analytics upload upload-log-file --filename "{args.filename}" --log-source-name "{args.log_source}" --namespace-name "{settings["namespace"]}" --opc-meta-loggrpid "{settings["log_group"]["id"]}" --upload-name "{args.name}" --file "{args.file}"''')
)

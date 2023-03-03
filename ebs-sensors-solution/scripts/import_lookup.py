import oci
import os
import sys, getopt

def main(argv):
    try:
        options, args = getopt.getopt(argv, "h:a:p:t:n:f:",
                                      ["authtype =",
                                       "profile =",
                                       "type =",
                                       "name =",
                                       "file ="])
        print('options: ', options)
        print('args: ', args)
    except:
        print("Error Message ")

    lookupType = ''
    lookupName = ''
    fileName = ''
    authType = 'user'
    profile = ''
    for name, value in options:
        if name in ['-a', '--authtype']:
            authType = value
        elif name in ['-p', '--profile']:
            profile = value
        elif name in ['-t', '--type']:
            lookupType = value
        elif name in ['-n', '--name']:
            lookupName = value
        elif name in ['-f', '--file']:
            fileName = value

    la_client = None
    object_storage_client = None
    try:
        if (authType == 'user'):
            config = oci.config.from_file("~/.oci/config", profile)
            la_client = oci.log_analytics.LogAnalyticsClient(config=config)
            object_storage_client = oci.object_storage.ObjectStorageClient(config=config)
        else:
            # get oci obo token from env var settings and create signer from obo delegation token
            obo_token = os.environ.get("OCI_obo_token")
            signer = oci.auth.signers.InstancePrincipalsDelegationTokenSigner(delegation_token=obo_token)
            # create LogAnalytics client using signer
            la_client = oci.log_analytics.LogAnalyticsClient(config={}, signer=signer)
            object_storage_client = oci.object_storage.ObjectStorageClient(config={}, signer=signer)

        namespace = object_storage_client.get_namespace().data

        if lookupName.startswith('"') and lookupName.endswith('"'):
            lookupName = lookupName[1:-1]

        # read the file body
        fileBody = open(fileName, "rb").read()

        lookup_response = la_client.register_lookup(
            namespace_name=namespace,
            type=lookupType,
            register_lookup_content_file_body=fileBody,
            name=lookupName)

        # Get the data from response
        print(lookup_response.data)

    except oci.exceptions.ServiceError as e:
        if e.status != 409:
            print("Error in adding lookup:",e, flush=True)
            raise
    except Exception as e:
        print(e,flush=True)
        raise e

if __name__ == "__main__":
    main(sys.argv[1:])

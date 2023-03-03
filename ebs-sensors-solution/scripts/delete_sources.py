import oci
import os,glob
import sys, getopt
import zipfile
import time
import xml.etree.ElementTree as ET

def main(argv):
    try:
        options, args = getopt.getopt(argv, "h:a:p:c:f:",
                                      ["authtype =",
                                       "profile =",
                                       "compartmentid =",
                                       "filepath ="])
        print('options: ', options)
        print('args: ', args)
    except:
        print("Error Message ")

    compartmentid = ''
    filepath = ''
    authType = 'user'
    profile = ''
    for name, value in options:
        if name in ['-a', '--authtype']:
            authType = value
        elif name in ['-p', '--profile']:
            profile = value
        elif name in ['-f', '--filepath']:
            filepath = value
        elif name in ['-c', '--compartmentid']:
            compartmentid = value

    try:
        # get source names from the given path
        sourcenames = []
        if (not filepath):
            print ("Error: Source filepath is empty!")
            return
        if filepath.startswith('"') and filepath.endswith('"'):
            filepath = filepath[1:-1]
        srcnames = getsourcenames(filepath)
        sourcenames = set(srcnames)

        print("######################### Source Details ######################")
        print("authtype :: ", authType)
        print("profile :: ", profile)
        print("compartment-id :: ", compartmentid)
        print("filepath :: ", filepath)
        print("sources :: ", sourcenames)

        la_client = None
        object_storage_client = None

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
        print("Tenancy NameSpace :: ", namespace)

        etag = ''
        for source in sourcenames:
            # escape source name
            #source = source.replace("\/", "%2F")
            # get source
            try:
                response = la_client.get_source(
                               namespace_name=namespace, 
                               compartment_id=compartmentid,
                               source_name=source)
                print("Get Source Response ::", response.headers)
                # get etag from get source response
                etag = response.headers.get("eTag")
            except oci.exceptions.ServiceError as e:
                if e.status == 404:
                    print("404 Error getting source: ", source)
                    continue
                print("Error in getting source :",e, flush=True)
                raise e

            print("Deleting source :: ", source)
            try:
                response = la_client.delete_source(
                               namespace_name=namespace, 
                               if_match=etag,
                               source_name=source)
                print("Delete response ::", response.headers)
            except oci.exceptions.ServiceError as e:
                if e.status != 404 or e.status != 409:
                    print("Error in deleting source :",e, flush=True)
                raise e
            except Exception as e:
                print(e,flush=True)
                raise e

    except Exception as e:
        print("Error in deleting sources: ",e)
        raise

def getsourcenames(filepath):
    archive_dir = filepath
    print("archive_dir :: ", archive_dir)

    source_names = []
    for archive in glob.glob(os.path.join(archive_dir, '*.zip')):
        print('archive ::', archive)
        #print('archive path ::', os.path.join(archive_dir, archive))
        with zipfile.ZipFile(archive, 'r') as z:
            for filename in z.namelist():
                print('filename ::', filename)
                if filename.lower().endswith('.xml'):
                    with z.open(filename, mode='r') as cfile:
                        tree = ET.parse(cfile)
                        root = tree.getroot()
                        print('root attributes:: ', root.attrib)

                        sources = root.findall('{http://www.oracle.com/DataCenter/LogAnalyticsStd}Source')
                        if (len(sources) == 0):
                            sources = root.findall('Source')

                        for src in sources:
                            sourcename = src.get('name')
                            print('src :',src.attrib)
                            print('src name:',sourcename)
                            if src not in source_names:
                                source_names.append(sourcename)
    return source_names

if __name__ == "__main__":
    main(sys.argv[1:])

import oci
import os,glob
import sys, getopt
import zipfile
import time
import xml.etree.ElementTree as ET

def main(argv):
    try:
        options, args = getopt.getopt(argv, "h:c:p:",
                                      ["compartmentid =",
                                       "path ="])
        print('options: ', options)
        print('args: ', args)
    except:
        print("Error Message ")

    compartmentid = ''
    path = ''
    for name, value in options:
        if name in ['-p', '--path']:
            path = value
        elif name in ['-c', '--compartmentid']:
            compartmentid = value

    try:
        # get source names from the given path
        sourcenames = []
        if (not path):
            print ("Error: Source path is empty!")
            return
        if path.startswith('"') and path.endswith('"'):
            path = path[1:-1]
        srcnames = getsourcenames(path)
        sourcenames = set(srcnames)

        print("######################### Source Details ######################")
        print("compartment-id :: ", compartmentid)
        print("path :: ", path)
        print("sources :: ", sourcenames)

        # get oci obo token from env var settings and create signer from obo delegation token
        obo_token = os.environ.get("OCI_obo_token")
        signer = oci.auth.signers.InstancePrincipalsDelegationTokenSigner(delegation_token=obo_token)
        # create LogAnalytics client using signer
        la_client = oci.log_analytics.LogAnalyticsClient(config={}, signer=signer)
        #Create Objectstorage client
        object_storage_client = oci.object_storage.ObjectStorageClient(config={}, signer=signer)

        namespace = object_storage_client.get_namespace().data
        print("Tenancy NameSpace :: ", namespace)

        etag = ''
        for source in sourcenames:
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
                if e.status != 404:
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

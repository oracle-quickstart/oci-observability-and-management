import oci
import os,glob
import sys, getopt
import zipfile
import time
import xml.etree.ElementTree as ET

def main(argv):
    try:
        options, args = getopt.getopt(argv, "h:o:a:p:c:e:l:f:",
                                      ["operation =",
                                       "authtype =",
                                       "profile =",
                                       "compartmentid =",
                                       "entityid =",
                                       "loggroupid =",
                                       "path ="])
        print('options: ', options)
        print('args: ', args)
    except:
        print("Error Message ")

    operation = ''
    compartmentid = ''
    entityid = ''
    loggroupid = ''
    filepath = ''
    authType = ''
    profile = ''
    for name, value in options:
        if name in ['-o', '--operation']:
            operation = value
        elif name in ['-a', '--authtype']:
            authType = value
        elif name in ['-p', '--profile']:
            profile = value
        elif name in ['-c', '--compartmentid']:
            compartmentid = value
        elif name in ['-e', '--entityid']:
            entityid = value
        elif name in ['-l', '--loggroupid']:
            loggroupid = value
        elif name in ['-f', '--filepath']:
            filepath = value

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

        print("######################### Source entity Associations Details ######################")
        print("operation :: ", operation)
        print("authtype :: ", authType)
        print("profile :: ", profile)
        print("compartment_id :: ", compartmentid)
        print("loggroup_id :: ", loggroupid)
        print("filepath :: ", filepath)
        print("sources :: ", sourcenames)
        print("entity_id :: ", entityid)


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

        # Before proceeding to add association(s), check if the entity is eligible
        # by looking at lifecycleState and lifecycleDetails
        maxRetries = 30
        while (maxRetries > 0):
            get_entity = la_client.get_log_analytics_entity(
                namespace_name=namespace,
                log_analytics_entity_id=entityid)
            lc_state = get_entity.data.lifecycle_state
            print("Entity State :: ", lc_state)
            if (lc_state == 'ACTIVE'):
                break
            elif (lc_state == 'DELETED'):
                print('Exit without creating/deleting assocs as the entity is in DELETED state')
                exit()
            else:
                print('Entity is still not ACTIVE. Current lifecycle state: ', lc_state)
            try:
                time.sleep(10)
            except Exception:
                continue

        if (operation == 'upsert'):
            items=[]
            for source in sourcenames:
                assoc = oci.log_analytics.models.UpsertLogAnalyticsAssociation(
                    agent_id=get_entity.data.management_agent_id,
                    source_name=source,
                    entity_id=entityid,
                    entity_name=get_entity.data.name,
                    entity_type_name=get_entity.data.entity_type_internal_name,
                    host=get_entity.data.hostname,
                    log_group_id=loggroupid)
                items.append(assoc)

            assocsToAdd=oci.log_analytics.models.UpsertLogAnalyticsAssociationDetails(
                compartment_id=compartmentid,
                items=items)

            # Read assoc payload from json file
            upsert_associations_response = la_client.upsert_associations(
                namespace_name = namespace,
                upsert_log_analytics_association_details = assocsToAdd,
                is_from_republish = False)

            print('upsert_associations_response:: ',upsert_associations_response.headers)
        elif (operation == 'delete'):
            items=[]
            for source in sourcenames:
                assoc = oci.log_analytics.models.DeleteLogAnalyticsAssociation(
                    agent_id=get_entity.data.management_agent_id,
                    source_name=source,
                    entity_id=entityid,
                    entity_type_name=get_entity.data.entity_type_internal_name,
                    host=get_entity.data.hostname,
                    log_group_id=loggroupid)
                items.append(assoc)
            assocsToDelete=oci.log_analytics.models.DeleteLogAnalyticsAssociationDetails(
                compartment_id=compartmentid,
                items=items)

            # Delete associations
            delete_associations_response = la_client.delete_associations(
                namespace_name=namespace,
                delete_log_analytics_association_details=assocsToDelete)
            print('delete_associations_response:: ', delete_associations_response.headers)
    except Exception:
        print('Error in adding or deleting source-entity association')
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

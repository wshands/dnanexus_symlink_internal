import os
import dxpy
import boto3
#import services.login_and_get_secret as login_and_get_secret
import login_and_get_secret

def lambda_handler(event, context):
    #project = "project-FPkJ6xj00Y3X88FKJ5Y12bgG" # Research Early Development - Dev
    #drive = "drive-jVv8ZQ7K9pYBJKYyzgbkqJGB"
    project = "project-GYgjXK80Yzg361fY4K7ffqb5" # migration dependencies

    out = "/symlinks"
    token = login_and_get_secret.get_secret()
    
    print(f"event:{event}")
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    name = os.path.basename(key)
    path = os.path.dirname(key)
    print(f"name:{name} path:{path}")
    
    eTag = event['Records'][0]['s3']['object']['eTag']
    client = boto3.client('s3')
    response_s3 = client.get_object_tagging(Bucket=bucket, Key=key)
    properties_s3 = response_s3['TagSet']
    length_s3 = len(properties_s3)
    property_md5sum = ""
    for index in range(0, length_s3):
        if properties_s3[index]['Key'] == "md5sum":
            property_md5sum = properties_s3[index]['Value']
    
    if "-" not in eTag:
        md5 = eTag.split("-")[0]
        print("Single-part upload, using eTag for md5sum")
    elif property_md5sum != "":
        md5 = property_md5sum
    else:
        print("Mulit-part uploaded file with no md5sum added as AWS property, cannot find symlink to modify... cancelling")
        quit()

    try:
        login_and_get_secret.login(token)
        
        files=dxpy.find_data_objects(classname="file", name=name, project=project, folder=out + "/" + path, tags=["symlink"], describe={"fields": {"md5": True}}, first_page_size=1000)
        for file in files:
            print("S3 file " + name + " found on DNAnexus in the correct location: " + file['id'])
            try:
                md5_dnanexus = file['describe']['md5']
            except:
                md5_dnanexus = ""
            if md5_dnanexus == md5:
                print("S3 file md5 matches DNAnexus file")
                dxpy.api.file_set_properties(object_id=file['id'], input_params={"project": project, "properties": {properties_s3[index]['Key']:properties_s3[index]['Value']}}, always_retry=True)
                print("AWS tag written/changed to DNAnexus property: " + properties_s3[index]['Key'] + ":" + properties_s3[index]['Value'])
            else:
                print("S3 file md5 does not match DNAnexus file")

    except Exception as e:
        print(e)
        raise e
        
    print('SUCCESS')

if __name__ == '__main__':
    lambda_handler()
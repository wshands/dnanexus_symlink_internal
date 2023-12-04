import json
import os
import dxpy
#import services.login_and_get_secret as login_and_get_secret
import login_and_get_secret

def lambda_handler(event, context):
    #project = "project-FPkJ6xj00Y3X88FKJ5Y12bgG" # Research Early Development - Dev
    #drive = "drive-jVv8ZQ7K9pYBJKYyzgbkqJGB"
    project = "project-GYgjXK80Yzg361fY4K7ffqb5" # migration dependencies
    out = "/symlink"
    token = login_and_get_secret.get_secret()
    
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    name = os.path.basename(key)
    path = os.path.dirname(key)

    try:
        login_and_get_secret.login(token)
        
        files=dxpy.find_data_objects(classname="file", name=name, project=project, folder=out + "/" + path, tags=["symlink"], describe={"fields": {"md5": True}}, first_page_size=1000)
        for file in files:
            print("S3 file " + name + " found on DNAnexus in the correct location: " + file['id'])
            output = dxpy.api.project_remove_objects(object_id=project, input_params={"objects": [file['id']], "force": True}, always_retry=True)
            fileid = json.loads(json.dumps(output))['id']
            print(f"File {name} deleted from DNAnexus")

    except Exception as e:
        print(e)
        raise e
        
    print('SUCCESS')

if __name__ == '__main__':
    lambda_handler()
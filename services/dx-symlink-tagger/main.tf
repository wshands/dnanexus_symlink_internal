provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Biogen = "symlink-s3-files-in-DNAnexus"
    }
  }
}

module "symlink_lambda" {   
  source = "../modules/dx-symlink-lambda"
  lambda_function_name = "DxSymlinkTagger"
  lambda_image_uri = "230407893272.dkr.ecr.us-east-1.amazonaws.com/dnanexus_symlink_tagger:main"
}

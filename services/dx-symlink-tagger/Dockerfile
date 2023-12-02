FROM public.ecr.aws/lambda/python:3.11
# https://docs.aws.amazon.com/lambda/latest/dg/python-image.html#python-image-instructions
# Example build: docker build --platform linux/amd64 -t waltslambda:test .
# (However doesn't run on a Mac OS)

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install the specified packages
RUN pip install -r requirements.txt

# Copy function code
COPY src/dx_symlink_tagger_lambda.py ${LAMBDA_TASK_ROOT}
COPY ../login_and_get_secret.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
# <handler file name>.<handler function name>
CMD [ "dx_symlink_tagger_lambda.lambda_handler" ]
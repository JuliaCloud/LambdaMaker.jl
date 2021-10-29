FROM public.ecr.aws/lambda/provided:al2

ARG FOLDER=1.6
ARG JULIA_VERSION=1.6.2
ARG SHA256="3eb4b5775b0df1ad38f6c409e989501ab445c95bcb01ab02bd60f5bd1e823240"

WORKDIR /usr/local

# Install security updates and tar gzip
RUN yum install yum-plugin-security
RUN yum install -y tar gzip

# Download the Julia x86_64 binary (only one compatible w/ AWS Lambda)
RUN curl -fL -o julia.tar.gz "https://julialang-s3.julialang.org/bin/linux/x64/${FOLDER}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz"

# Check the SHA256 hash, exit if they do not match
RUN echo "${SHA256} julia.tar.gz" | sha256sum -c || exit 1

# Extract Julia and create a SymLink
RUN tar xf julia.tar.gz
RUN ln -s "julia-${JULIA_VERSION}" julia

# Install the application
WORKDIR /var/task

# Use a special depot path to store precompiled binaries
ENV JULIA_DEPOT_PATH /var/task/.julia

# Instantiate project and precompile packages
COPY Manifest.toml .
COPY Project.toml .
RUN /usr/local/julia/bin/julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.API.precompile()"

# Copy application code
COPY . .

# Uncomment this line to allow more precompilation in lamdbda just in case.
# That's because /var/task is a read-only path during runtime.
ENV JULIA_DEPOT_PATH /tmp/.julia:/var/task/.julia

# Install bootstrap script
WORKDIR /var/runtime
COPY bootstrap .

# Create an empty extensions directory
WORKDIR /opt/extensions

# Which module/function to call?
CMD [ "{{{PKG}}}.handle_event"]

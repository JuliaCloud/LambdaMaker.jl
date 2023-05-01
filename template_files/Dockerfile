FROM public.ecr.aws/lambda/provided:al2

ARG FOLDER=1.8
ARG JULIA_VERSION=1.8.5
ARG SHA256="e71a24816e8fe9d5f4807664cbbb42738f5aa9fe05397d35c81d4c5d649b9d05"

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
# LD_LIBRARY_PATH is cleared due to https://github.com/JuliaLang/julia/issues/46409
RUN LD_LIBRARY_PATH="" /usr/local/julia/bin/julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.API.precompile()"

# Copy application code
COPY . .

# Setup the JULIA_DEPOT_PATH
ENV JULIA_DEPOT_PATH /tmp/.julia:/var/task/.julia

# Install bootstrap script
WORKDIR /var/runtime
COPY bootstrap .

# Create an empty extensions directory
WORKDIR /opt/extensions

# Which module/function to call?
CMD ["{{{PKG}}}.handle_event"]

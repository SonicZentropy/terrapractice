project := justfile_directory()
s3 := project + "/global/s3"
webserver := project + "/stage/services/webserver-cluster"
postgres := project + "/stage/data-stores/postgres"
kube := project + "/kube-eks/"
rust_backend := project + "/stage/services/rust_backend"

@rust_backend *cmd:
    cd {{rust_backend} && {{cmd}}

# staging webserver
@web *cmd:
    cd {{webserver}} && just {{cmd}}

# global s3
@s3 *cmd:
    cd {{s3}} && just {{cmd}}

# global s3
@postgres *cmd:
    cd {{postgres}} && just {{cmd}}

# K8ns
@kube *cmd
    cd {{kube}} && just {{cmd}}

# Used like `just s3 plan` or `just webserver init`
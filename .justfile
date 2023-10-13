project := justfile_directory()
s3 := project + "/global/s3"
webserver := project + "/stage/services/webserver-cluster"

# staging webserver
@webserver *cmd:
    cd {{webserver}} && just {{cmd}}

# global s3
@s3 *cmd:
    cd {{s3}} && just {{cmd}}

# Used like `just s3 plan` or `just webserver init`
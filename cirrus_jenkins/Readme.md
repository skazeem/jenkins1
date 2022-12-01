This repositary consist of Docker file and related images to run jenkins pre-populated jobs:
============================================================================================

How to use
----------------

Excute the below commond to build the docker image as follows:
``` 
docker build -t <image-name> .
```

After building the docker image successfully, Now excute the command to create a contrainer out of the image:
```
#docker run -itd --name <container-name> <host-port>:<container-port> <image-name> 
```
Example:
-------
```
docker build -t Jenkins_v1 .
docker run -itd --name Jenkins_v1 8080:8080 <image-name> 
```

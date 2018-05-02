# Azure-App-Service-WordPress

A Docker container solution for WordPress on Azure Web App for Containers

* [Overview](#overview)
* [Bring your own code](#byo-code)
* [Bring your own database](#byo-database)
* [Persistent Files](#files)
* [References](#references)

<a id="overview"></a>
## Overview

In September 2017 [Microsoft announced the general availability](https://azure.microsoft.com/en-us/blog/general-availability-of-app-service-on-linux-and-web-app-for-containers/) of Azure Web App for Containers and Azure App Service on Linux.

While it is possible to host WordPress websites with Azure App Service on Linux, its built-in image for PHP is not an ideal environment for WordPress in production. At SNP we turned our attention to the Web App for Containers resource as a way to provide custom Docker images for our customers. Our priorities were to:

* Include WordPress code in the image, not referenced from the Web App /home mount.
* Set custom permissions on the document root.
* Add more PHP extensions commonly used by WordPress sites
* Add additional PHP configuration settings recommended for WordPress

This repository is an example solution for WordPress. By itself, this solution does not install WordPress. *You need to bring your own code and database.* (More about this below.) 

This repository is intended to satisfy common WordPress use cases. We expect that users of this solution will customize it to varying degrees to match their application requirements. For instance, we include many PHP extensions commonly required by WordPress, but you may need to add one or more (or remove ones that you do not need).

### What are the customizations for WordPress?

The origin of this repository is a Docker solution for an [Azure App Service on Linux, PHP 7.2.1 base image](https://github.com/Azure-App-Service/php/tree/master/7.2.1-apache).

Our initial, significant changes are seen in the commit [6c27d0f](https://github.com/snp-technologies/Azure-App-Service-WordPress/commit/6c27d0fc07300588dc1219f97f658d850e644850).

<a id="byo-code"></a>
## Bring your own code

In the Dockerfile, there is a placeholder for your code: "[REPLACE WITH YOUR GIT REPOSITORY CLONE URL]". Alternatively, you can use the Docker COPY command to copy code from your local disk into the image.

Our recommendation is to place your code in a directory directly off the root of the repository. In this repository we provide a ```docroot``` directory into which you can place your WordPress application code. In the Dockerfile, it is assumed that the application code is in the ```docroot``` directory. Feel free, of course, to rename the directory with your preferred naming convention.

<a id="byo-database"></a>
## Bring your own database

MySQL (or other WordPress compatible database) is not included in the Dockerfile. 
You can add this to the Dockerfile, or utilize an external database resource such as [Azure Database for MySQL](https://docs.microsoft.com/en-us/azure/mysql/).

### Connection string tip

The Azure Web App provides a setting into which you can enter a database connection string. 
This string is an environment variable within the Web App. 
At run-time, this environment variable can be interpretted in your wp-config.php file and 
parsed to populate your MySQL settings. 

An alternative to the Web App Connection string environment variable is to reference 
in wp-config.php a secrets file mounted to the Web App /home directory. 
For example, assume that we have a secrets.php file that contains:
```
<?php
  $wgDBserver="myhost.mysql.database.azure.com"; 
  $wgDBname="mydb"; 
  $wgDBuser="myuser@myhost";  
  $wgDBpassword="mypw";
?>
```
In our wp-config.php file, we can use the following code to populate the MySQL settings:
```
require_once("/home/secrets.php"); 

/** MySQL hostname */
define('DB_HOST', $wgDBserver);

/** MySQL database name */
define('DB_NAME', $wgDBname);

/** MySQL database username */
define('DB_USER', $wgDBuser);

/** MySQL database password */
define('DB_PASSWORD', $wgDBpassword);

```
<a id="files"></a>
## Persistent Files

In order to persist files, we leverage the Web App's /home directory that is mounted to Azure File Storage (see NOTE below).
The /home directory is accessible from the container. 
As such, we persist files by making directories and then setting symbolic links, as follows:
```
# Add directories for public and private files
# Add directories typically not included in the git repository
# These are mounted from /home

RUN mkdir -p  /home/site/wwwroot/wp-content/uploads/ \
    && ln -s /home/site/wwwroot/wp-content/uploads  /var/www/html/docroot/wp-content/uploads \
    && mkdir -p  /home/site/wwwroot/wp-content/backup-db/ \
    && ln -s /home/site/wwwroot/wp-content/backup-db  /var/www/html/docroot/wp-content/backup-db \
    && mkdir -p  /home/site/wwwroot/wp-content/backups/ \
    && ln -s /home/site/wwwroot/wp-content/backups  /var/www/html/docroot/wp-content/backups \
    && mkdir -p  /home/site/wwwroot/wp-content/blogs.dir/ \
    && ln -s /home/site/wwwroot/wp-content/blogs.dir  /var/www/html/docroot/wp-content/blogs.dir \
    && mkdir -p  /home/site/wwwroot/wp-content/cache/ \
    && ln -s /home/site/wwwroot/wp-content/cache  /var/www/html/docroot/wp-content/cache \    
    && mkdir -p  /home/site/wwwroot/wp-content/upgrade/ \
    && ln -s /home/site/wwwroot/wp-content/upgrade  /var/www/html/docroot/wp-content/upgrade
```

NOTE: By default, the Web App for Containers platform mounts an SMB share to the /home/ directory. You can do that by setting the `WEBSITES_ENABLE_APP_SERVICE_STORAGE` app setting to true or by removing the app setting entirely.

If the `WEBSITES_ENABLE_APP_SERVICE_STORAGE` setting is false, the /home/ directory will not be shared across scale instances, and files that are written there will not be persisted across restarts.

<a id="references"></a>
## References

* [Docker Hub Official Repository for php](https://hub.docker.com/r/_/php/)
* [Web App for Containers home page](https://azure.microsoft.com/en-us/services/app-service/containers/)
* [Use a custom Docker image for Web App for Containers](https://docs.microsoft.com/en-us/azure/app-service/containers/tutorial-custom-docker-image)
* [Understanding the Azure App Service file system](https://github.com/projectkudu/kudu/wiki/Understanding-the-Azure-App-Service-file-system)
* [Azure App Service on Linux FAQ](https://docs.microsoft.com/en-us/azure/app-service/containers/app-service-linux-faq)

Git repository sponsored by [SNP Technologies](https://www.snp.com)

If you are interested in a Drupal 7 container solution, please visit https://github.com/snp-technologies/Azure-App-Service-Drupal7.



# mycapapp
## CAP Based NodeJS app

In this article I am going to explain steps which you can follow to quickly create an application using SAP Cloud Application Programming Model. CAP supports both NodeJS and JAVA. We will be looking at NodeJS option in this article.

There are of course lots of articles and videos on this topic out there but what I am going to do here is to provide you steps in a concise way so that you are able to start quickly with CAP. This will help you if you are short on time and just need a quick tutorial to get started.

Steps to create a CAP Node JS Project

* `cds init <appname>`

   This will initialize a Node JS CAP Application. In the project structure you will have three folders and a package.json file:
    
   * `app` - This folder will hold the UI artifacts

   * `db` - This folder will hold the entity schema in the form of a schema.cds file. In CAP app, the db folder does not hold the .hdbtable and .hdbview etc. artifacts contrary to BTP HANA application. It will be possible to specify if we do not want to create corresponding HANA tables for entities by using the annotation `@cds.persistence.exists`.

   * `srv` - This folder will contain the OData service definition in the form of one or more `service.cds` files. If we want to implement our own coding then a JS file should be created here with the same name as the `service.cds` file but with extension .js. ( It is possible to have a different implementation file name by specifying the file name in `service.cds` file with annotation `@impl : './myserviceimpl.js'`.

   * `package.json` - package json will have dependency on `express` and `@sap/cds` only at this stage.

   At this moment we can use cds watch command to start the project but nothing will happen since there is no cds file in db or srv folder yet. cds run command will not work without .cds file. After adding a cds file containing an entity schema in db folder we can use either watch or run command. cds watch command is like nodemon command and it will keep on observing the project for any changes and will automatically serve new content.

* `cds add hana`

   To add HANA support into the project. It will add :

   * cds section in the `package.json` file with value of `requires.db.kind` as `sql`. What this will do is to add support for SQLite in the dev environment and HANA support in the production environment so that we need not change the package file setting again and again. If you wish to work with HANA only during development then change this value from `sql` to `hana`. This way the `cds build` command will generate artifacts in `.hdbtable` and `.hdbview` formats in the `gen/db/src` folder. If the value is `sql` then in dev environment no db artifacts are generated, but if you still want to generate HANA specific artifacts(just to check them before deploying to HANA) you can use the `--production` switch with `cds build` like: `cds build --production`.

   * hdb dependency in the `package.json` file. hdb is the JavaScript HANA DB Client provided by SAP as a node package. It is recommended to use `@sap/hana-client` (not sure why it was not added and hdb was added?).

   * the file `src/.hdiconfig` in db folder.

* `cds deploy --to hana:<CF hana service instance name>`

   This command will first compile the CDS models into HANA artifacts and generate a `gen/db` folder in root of project. The `gen` folder will have only db subfolder with `manifest.yml` file.

   Then it will deploy the HANA artifacts generated to the HDI container which is specified after colon. Otherwise It will first create automatically an HDI container if the HANA service instance name is not specified by using command `cf create-service hana hdi-shared <projectname>-db`.

   This command will just do the deployment of db part of project to HANA. What this command will also do at this stage is to enable local testing in BAS(or on VSCode as well) by creating `default-env.json` file with `VCAP_SERVICES` env variable. Still at this stage no `cf push` has been done for the `srv` module. The srv app is in local dev environment but db has been moved to HANA on CF.


* `cds deploy --to sqlite:<dbfilename>`

   This will deploy the db to a locally persisted SQLite database with name <dbfilename>. If filename is omitted then the default name SQLite.db will be picked.

* `cds run or cds watch`

   To run the app locally in the dev environment.

* `CDS_ENV=production cds run`

   To run the app locally but with HANA backend. This is needed because by default the framework will fall back to SQLite in local development so the environment variable needs to be set. `cds deploy --to hana` is pre-requisite for this command to work. Alternatively if you have specified `hana` in the data source in `package.json` file in cds section `requires.db.kind`, then `cds run` or `cds watch` will nevertheless always run with hana only and there is no need to set the environment variable to `production`.

## Push the app to CF

* `cds build`

   In the root of the project execute the build command to build the project. This command will create `gen` folder in root of project. The `gen/srv` folder will have `manifest.yml` file. The YAML file will be generated with all the dependencies like dependency on HANA service so that a `cf push` can happen.
   `cds build` will just build the `srv` module when executed in the dev environment because a `cds deploy --to hana` would mostly have been done already. We can then use `cf push` to push the `gen/srv` module after updating the manifest file with name of HDI container in services section.

   _Note: The services section somehow is empty after cds build step. Ideally it should have 'HANA service instance name' which was specified during the `cds deploy to hana` step but it is not picking it up._
  
  `cds build --production`
   
   If cds build command is used with switch `--production` then the `gen` folder will have both `db` and `srv` subfolders. 

   The `gen/db` subfolder will have details of HANA Deployer app which is just a vehicle for transporting HANA artifacts to CF and deploy them. This app can be stopped/deleted in CF once deployment is successful. This folder will also have subfolder `src/gen` containing the HANA artifacts in `.hdbtable` and `.hdbview` etc. formats. 
   
   The `gen/srv` subfolder will have details of service module and can be pushed to CF as any other NodeJS app.

   In this approach `cds deploy --to hana` is not a pre-requisite since we will be push the db deployer app separately. But this approach will also not enable local dev environment for testing with hana.

* `cf push`

    __Prerequisite__ : The HDI container needs to be created before hand since `cf push` does not create the dependent services specified in the `services` section of manifest file. Use the command `cf create-service hana hdi-shared <projectname-db>` to create the hdi container before pushing the db deployer app.

   cd into the `gen/db` and `gen/srv` folder and then issue command `cf push`. It will push the db deployer app and srv app and bind the srv app to the HDI container instance.

## Additional Commands

* `cds compile srv/service.cds (or db/schema.cds) --to sql`

   Will give out the SQL DDL statements

* `cds compile db/schema.cds --to hana`

   Does not work even though this command was shown in openSAP course. Reason could be that this command was generating .hdbcds format artifacts which are not supported anymore with HANA Cloud. Internally the cds deploy - to hana command must still be compiling to .hdbtable and other formats as per HANA cloud.
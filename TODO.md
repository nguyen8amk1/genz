# NOTE
**THESE FILES ONLY WORKS WHEN COPIES INTO ANOTHER APP** 
-> do we have any way to test this as a completely independent project  


# GOAL
-> **GENERATE A (VERY OPINIONATED) FULLSTACK (JAVASCRIPT) CI/CD PROJECT
    WITH A SIMPLE COMMAND** 
    vd: `genz --full ` 

Currently we have 
    + 1. a dev docker environment management tool  
    + 2. a prod docker environment management tool (kinda :v)  
    but we still not have the:
        + needed dockerfiles, dockercompose [] @Current 
        + init code  
        + test ?? 

+ Group pieces of the tool into a single place and work with that 
    -> DO LIKE GIT 
        -> **HAVING A GLOBAL PROGRAM THAT WORKS WITH LOCAL METADATA**
        -> **MAP TO A GIT WORKFLOW**
        init an ci/cd-based project  
            -> generate a metadata file 
            -> **WE DON'T NEED A SUBMODULE ANYMORE 
                SINCE THE TOOL IS GLOBAL THROUGH THE WHOLE COMPUTER**  
            -> **ANY CHANGE APPLY GLOBALLY ALL THE TIME** 

    -> genz is like artisan     
        deals with everything from build/run frontend, backend, database migration, ...
            have all the frontend, backend, database detail information in the metadata
        + List all the files that each of the components need in the metadata as well:
            + vd: 
                frontend: 
                    frontend directory path 
                    dev-dockerfile
                    prod-dockerfile
                    nginx-conf 
                    images-names, containers-names
                backend: 
                    backend directory path 
                    dev-dockerfile
                    prod-dockerfile
                    images-names, containers-names

        + vd:   genz frontend --build 
                genz backend --build 


# TODO: 
**BUILD THE TOOL INTO EXECUTABLE EVERYTIME A NEW VERSION AVAILABLE**  
**SINGLE-DIRECTION DEPENDENCY, EVERYTHING(DOCKER, CODE,...) HAVE TO STEM FROM THE project.json metadata**
**THE DEFAULT COMMANDS IS ONLY FOR **

write an argpargs system 
    that generates a "WORKING OPINIONATED PROJECT"

**TRY TO MAKE THE CURRENTLY EXISTING WEB APP WORKS WITH THE NEW TOOL SYSTEM**
    Migrate from 
        client/dev.sh --build -> genz frontend --build 
            -> wrap the old dev.h code with the genz frontend command [] 
        Make the start command works [X]
            genz frontend:start  == client/dev.sh 
                -> run and link 
        Make the `build` command works [] @Current


# DONE 




## Problems: 
The problem we currently have when updating the tool is 
the web app that uses this tool currently have very separated structure
-> Each Components use each piece of the tool
-> The tool is distributed -> hard to update correctly because we don't know where the pieces of the tool is 


+ 2 solutions: 
    + Find a way to deal with the distributed tool pieces 
        -> **HAVING A LOCAL PROGRAM THAT WORKS WITH LOCAL METADATA**
            -> genz is just a program that generates: 
                a project with distributed parts of web app with distributed tools 
                -> each parts of the web app (frontend, backend, database,...) 
                    each of them have their own tools
                        have their own sets of commands and work directly with the files in the folder structure 
                    vd: <frontend dir>/dev.sh  --build 
                        <backend dir>/dev.sh  --build 

        + Pros: 
            
        + cons: 
            fucking hard to do and i don't know if i can do it properly 
    
    
    + Group pieces of the tool into a single place and work with that 
        -> DO LIKE GIT 
            -> **HAVING A GLOBAL PROGRAM THAT WORKS WITH LOCAL METADATA**
            -> **MAP TO A GIT WORKFLOW**
            init an ci/cd-based project  
                -> generate a metadata file 
                -> **WE DON'T NEED A SUBMODULE ANYMORE 
                    SINCE THE TOOL IS GLOBAL THROUGH THE WHOLE COMPUTER**  
                -> **ANY CHANGE APPLY GLOBALLY ALL THE TIME** 


        -> genz is like artisan     
            deals with everything from build/run frontend, backend, database migration, ...
                have all the frontend, backend, database detail information in the metadata
            + List all the files that each of the components need in the metadata as well:
                + vd: 
                    frontend: 
                        frontend directory path 
                        dev-dockerfile
                        prod-dockerfile
                        nginx-conf 
                        images-names, containers-names
                    backend: 
                        backend directory path 
                        dev-dockerfile
                        prod-dockerfile
                        images-names, containers-names

            + vd:   genz frontend --build 
                    genz backend --build 


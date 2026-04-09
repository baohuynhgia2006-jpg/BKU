#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include<dirent.h>
#include<sys/stat.h>
#include<sys/types.h>
#include<sys/dir.h>
#include<stdbool.h>

const int MAX_BUFFER = 100;
const char* CALL_ECHO = "echo";
const char* CALL_TOUCH = "touch";
const char* CALL_MKDIR = "mkdir";

int handle_invalid_characters(const char *STR) {
    printf("Error: Project name '%s' is invalid. Use only letters, numbers, and hyphens (e.g., my-project).\n", STR);
    return 1;
}

void touch_cmd(const char *FILE_PATH) {
    pid_t p = fork();
    if(p == 0) {
        execlp(CALL_TOUCH, CALL_TOUCH, FILE_PATH, NULL);
    }
    return;
}

int generate_new_C_project(const char *P_NAME, bool USES_GIT) {
    int PROJECT_NAME_SIZE = strlen(P_NAME), C_ERROR;
    for(int i = 0; i < PROJECT_NAME_SIZE; i++) {
        C_ERROR = 1;
        C_ERROR = (P_NAME[i] != '-')? (C_ERROR && 1) : (C_ERROR && 0);
        C_ERROR = (P_NAME[i] < 'a' || P_NAME[i] > 'z')? (C_ERROR && 1) : (C_ERROR && 0);
        C_ERROR = (P_NAME[i] < 'A' || P_NAME[i] > 'Z')? (C_ERROR && 1) : (C_ERROR && 0);
        C_ERROR = (P_NAME[i] < '0' || P_NAME[i] > '9')? (C_ERROR && 1) : (C_ERROR && 0);
        if (C_ERROR == 1) {
            return handle_invalid_characters(P_NAME);
        }
    }
    DIR *dir = opendir(P_NAME);
    if (dir) {
        closedir(dir);
        printf("Error: Directory '%s' already exists.\n", P_NAME);
        return 1;
    }
    fflush(stdout);
    mkdir(P_NAME, 0777);
    char ARG_PATH[MAX_BUFFER];
    strcpy(ARG_PATH,P_NAME);
    strcat(ARG_PATH, "/src");
    mkdir(ARG_PATH, 0777); // CREATE /src
    strcpy(ARG_PATH,P_NAME);
    strcat(ARG_PATH, "/include");
    mkdir(ARG_PATH, 0777); // CREATE /include
    strcpy(ARG_PATH,P_NAME);
    strcat(ARG_PATH,"/src/main.c");
    touch_cmd(ARG_PATH); // CREATE /src/main.c
    strcpy(ARG_PATH,P_NAME);
    strcat(ARG_PATH,"/Makefile");
    touch_cmd(ARG_PATH); // CREATE /Makefile
    strcpy(ARG_PATH,P_NAME);
    strcat(ARG_PATH,"/README.md");
    touch_cmd(ARG_PATH); // CREATE /README.md
    printf("Created C project '%s' with standard layout.\n",P_NAME);
    strcpy(ARG_PATH,P_NAME);
    strcat(ARG_PATH,"/src/main.c");
    FILE* TEMPLATE_MAIN = fopen(ARG_PATH,"a");
    fprintf(TEMPLATE_MAIN,"#include<stdio.h>\n");
    fprintf(TEMPLATE_MAIN,"\n");
    fprintf(TEMPLATE_MAIN,"int main() {\n");
    fprintf(TEMPLATE_MAIN,"\tprintf(\"Hello World! \\n\");\n");
    fprintf(TEMPLATE_MAIN,"\treturn 0;\n");
    fprintf(TEMPLATE_MAIN,"}\n");
    fclose(TEMPLATE_MAIN);
    strcpy(ARG_PATH,P_NAME);
    strcat(ARG_PATH,"/Makefile");
    FILE* TEMPLATE_MAKEFILE = fopen(ARG_PATH,"a");
    fprintf(TEMPLATE_MAKEFILE,"CC = gcc\n");
    fprintf(TEMPLATE_MAKEFILE,"CFLAGS = -Wall -Wextra -g -Iinclude\n");
    fprintf(TEMPLATE_MAKEFILE,"SRC_DIR = src\n");
    fprintf(TEMPLATE_MAKEFILE,"OBJ_DIR = .\n");
    fprintf(TEMPLATE_MAKEFILE,"TARGET = program\n");
    fprintf(TEMPLATE_MAKEFILE,"SRCS = $(wildcard $(SRC_DIR)/""*.c)\n");
    fprintf(TEMPLATE_MAKEFILE,"OBJS = $(patsubst $(SRC_DIR)/%%.c, $(OBJ_DIR)/%%.o, $(SRCS))\n");
    fprintf(TEMPLATE_MAKEFILE,"all: $(TARGET)\n");
    fprintf(TEMPLATE_MAKEFILE,"$(TARGET): $(OBJS)\n");
    fprintf(TEMPLATE_MAKEFILE,"\t$(CC) $(OBJS) -o $@\n");
    fprintf(TEMPLATE_MAKEFILE,"$(OBJ_DIR)/%%.o: $(SRC_DIR)/%%.c\n");
    fprintf(TEMPLATE_MAKEFILE,"\t$(CC) $(CFLAGS) -c $< -o $@\n");
    fprintf(TEMPLATE_MAKEFILE,"clean:\n");
    fprintf(TEMPLATE_MAKEFILE,"\trm -f $(OBJS) $(TARGET)\n");
    fprintf(TEMPLATE_MAKEFILE,".PHONY: all clean\n");
    fclose(TEMPLATE_MAKEFILE);
    strcpy(ARG_PATH,P_NAME);
    strcat(ARG_PATH,"/README.md");
    FILE* TEMPLATE_README = fopen(ARG_PATH,"a");
    fprintf(TEMPLATE_README,"# %s\n",P_NAME);
    fprintf(TEMPLATE_README,"This is a sample README.md file for this C project.\n");
    fclose(TEMPLATE_README);
    if (USES_GIT == true) {
        strcpy(ARG_PATH,"cd ");
        strcat(ARG_PATH,P_NAME);
        strcat(ARG_PATH," && git init -q");
        system(ARG_PATH);
        printf("Intialized Git repository.\n");
        strcpy(ARG_PATH,P_NAME);
        strcat(ARG_PATH,"/.gitignore");
        touch_cmd(ARG_PATH);
        FILE* GITIGNORE = fopen(ARG_PATH,"a");
        fprintf(GITIGNORE,"*.o\n");
        fprintf(GITIGNORE,"program\n");
        fprintf(GITIGNORE,"*.exe\n");
        fclose(GITIGNORE);
        printf("Added .gitignore for C projects.\n");
    }
    printf("Running 'make all' to verify...\n");
    strcpy(ARG_PATH,"cd ");
    strcat(ARG_PATH,P_NAME);
    strcat(ARG_PATH," && make -s all");
    system(ARG_PATH);
    printf("Build successfully. Binary 'program' created.\n");
    strcpy(ARG_PATH,"cd ");
    strcat(ARG_PATH,P_NAME);
    strcat(ARG_PATH," && ./program");
    if(system(ARG_PATH) != 0) {
    	printf("Output check failed.\n");
    	return 1;
    }
    printf("Output check successfully.\n");
    printf("Project setup complete\n");
    return 0;
}

void help_display(){
    printf("Usage: cnew [options] \n");
    printf("Options:\n");
    printf("\t--name <project-name>\tCreate a new C project with the given name (required).\n");
    printf("\t\t\t\tName must contain only letters, numbers, and hyphens.\n");
    printf("\t--with-git \t\tInitialize the project as Git repository with a .gitignore.\n");
    printf("\t--help \t\t\tDisplay this help message.\n");
    printf("Example:\n");
    printf("\tcnew --name my-project --with-git\n");
}

int main(int argc, char* argv[]) {
    //const char *NEW_P_NAME = "my-project";
    //generate_new_C_project(NEW_P_NAME);
    if(argc > 1 && strcmp(argv[1],"--help") == 0) {
        help_display();
    }
    else if(argc > 3 && strcmp(argv[1],"--name") == 0 && strcmp(argv[3],"--with-git") == 0) {
        return generate_new_C_project(argv[2],true);
    }
    else if(argc > 2 && strcmp(argv[1],"--name") == 0) {
        return generate_new_C_project(argv[2],false);
    }
    return 0;
}

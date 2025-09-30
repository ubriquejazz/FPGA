// www.it.uc3m.es/pbasanta/asng/course_notes/
// c_threads_race_mutex_en.html
// C/ Ferraz 6, piso 3B

pthread_mutex_t mutex;

void* thread_run(void* data)
{ 
    int i_data;
    sleep(2); 
    printf("[TH_ID:%ld]: Hello from the thread \n", pthread_self());
    
    pthread_mutex_lock(&mutex);
    printf("[TH_ID:%ld]: Reading %i \n", pthread_self(),(*(int*)data));  
    i_data=(*(int*)data);
    sleep(1); //It should be removed
    i_data++;
    (*(int*)data)=i_data;  
    printf("[TH_ID:%ld]: Writing %i \n", pthread_self(),(*(int*)data));
    
    pthread_mutex_unlock(&mutex);
    printf("[TH_ID: %ld]: To exit...............\n",pthread_self());
    return data;
}


int main()
{ 
    int i;
    pthread_t thread[2];
    int data=0;

    if(pthread_mutex_init(&mutex,NULL)!=0) 
        return -1;

    for (i=0;i<2; i++)
    { 
        printf("[MAIN:%ld]: Starting............ \n",pthread_self());
        if (pthread_create(&thread[i],NULL,thread_run,&data)!=0)
            return -1;
    }

    sleep(1);
    printf("[MAIN:%ld]: Thread allocated \n",pthread_self());
    int *ptr_output_data;
    ptr_output_data = &data;

    for ( i=0;i<2; i++)
        pthread_join(thread[i],(void **)&ptr_output_data);

    pthread_mutex_destroy(&mutex);
    printf("[MAIN:%ld]: Thread returns %d \n",pthread_self(), *ptr_output_data);
    return 0;
} 


/* LOGS

[MAIN:1]: Starting............ 
[MAIN:2]: Starting............ 
[MAIN:2]: Thread allocated 
[TH_ID:0]: Hello from the thread 
[TH_ID:0]: Reading 0 
[TH_ID:0]: Writing 1 
[TH_ID:0]: To exit...............
[TH_ID:1]: Hello from the thread 
[TH_ID:1]: Reading 1 
[TH_ID:1]: Writing 2 
[TH_ID:1]: To exit...............
[MAIN:2]: Thread returns 2
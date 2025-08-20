module sql_test03;

import connector;
import sqlite3;
import libc;
import std;

extern fn int printf(char*,...);

fn int my_callback(void* arg,int howmany,char** cvalues,char** cnames) 
{
		for( int i=0;i<howmany;i++) {
			printf("|%s\t%s\n",cnames[i],cvalues[i]);
		}
	
	printf("|\n");
	return 0;
}

fn void main() {

   
	SqliteConnector connector;

	
	if(connector.open("world.db3")!=sqlite3::OK)
    {
        printf("Failed to connect to database.");
    }
    printf("Connect to database ok\n");
    
    
	
	String query = "select count(*) from city";
	
	connector.prepare(query);
	connector.step();
    
    long nr_cities=connector.column_int64(0);
    printf("There are %d cities in the database.\n",nr_cities);
    
	int nr_id = connector.column_int(0);
	printf("There are %d ids in the database.\n",nr_id);
    
    
    
    connector.finalize();
	printf("Before the long dataset retrieving,let's pause a second.\n");
    libc::system("pause");
    
    
	ZString* error_msg ;
	String query_all_cities = "select * from city";
	ResultStatus rc = connector.execute(query_all_cities, (ExecCallback)&my_callback, (void*)(7), error_msg);
	if (rc != sqlite3::OK) {
		printf("Error :%s\n",error_msg) ;
		connector.free((char*)error_msg);
	}
    
    printf("trying to retrieving data by the new generic column method:\n");
    libc::system("pause");
    
    connector.prepare(query_all_cities);
    int columns=connector.column_count();
    printf("There are total %d columns in the query\n",columns);
    libc::system("pause");
    while(connector.step())
    {
        for(int i=0;i<columns;i++)
        {
            
            if((i==1))
            {
                printf("%20s",connector.@column(i,String));
            }
            else if(i==3)
            {
                printf("%30s",connector.@column(i,String));
            }
            else if(i==4)
            {
                printf("%12d",connector.@column(i,ulong));
            }
            else if(i==0)
            {
                printf("%6d",connector.@column(i,ushort));
            }
            else
            {
                printf("%12s",connector.@column(i,String));
            }
        }
        printf("\n");
    }
    
    printf("Now let us do a filter query.");
    printf("Please enter a max id:");
    uint? id=io::treadline().to_uint();
    if(catch err=id)
    {
        id=0;
    }
    connector.prepare("select * from city where id>?");
    connector.@bind(1,id)!!;
    connector.step();
    String result=connector.@column(3,String);
    printf("first row 3rd column:%s\n",result);
    
    libc::system("pause");
    
    printf("No exec only prepare + step\n");
    //connector.exec("select * from city where ID>4000;");
    connector.prepare("select * from city where ID>4000;");
    while(connector.next())
    {
        for(int i=0;i<columns;i++)
        {
            printf("\t%s\t",connector.@column(i,String));
        }
        printf("\n");
    }
    
    libc::system("pause");
    printf("Using exec to retrieve records in one shot.\n");
    uint changes=connector.exec("select * from city where ID>4000;");
    printf("Total %d records changed.\n",changes);
    
     do
    {
        for(int i=0;i<columns;i++)
        {
            printf("\t%s\t",connector.@column(i,String));
        }
        printf("\n");
    }while(connector.next());
    
    libc::system("pause");
    printf("Using query to retrieve records in one shot.\n");
    changes=connector.query("select * from city where ID>4050;");
    printf("Total %d records changed.\n",changes);
    
    do
    {
        for(int i=0;i<columns;i++)
        {
            printf("\t%s\t",connector.@column(i,String));
        }
        printf("\n");
    }while(connector.next());
    
    connector.reset();
    //connector.query("select count(*) from city;");
   
    libc::printf("Total records: %d\n",connector.total_count("city"));
    
    connector.reset();
    libc::printf("The largets ID of all records is %d\n",connector.max_id("city","id"));
	connector.close();
}
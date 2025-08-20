module connector;

import sqlite3;
import libc;
enum State
{
    CLOSED,
    PREPARED,
    OPEN
}
struct SqliteConnector
{
    SqliteHandle db;
    SqliteStmt cmd;
}
fn ResultStatus SqliteConnector.init(&self,String db_name)
{
	
    sqlite3::open(db_name.zstr_tcopy(),&self.db);
    if(!self.db) return sqlite3::ERROR;
    
    return sqlite3::OK;
    
}
fn ResultStatus SqliteConnector.open(&self,String db_name)
{
    return sqlite3::open(db_name.zstr_tcopy(),&self.db);
}

fn ResultStatus SqliteConnector.prepare(&self,String cmd)
{
    return sqlite3::prepare_v2(self.db,cmd.zstr_tcopy(),cmd.len,&self.cmd,null);
}

fn int SqliteConnector.query(&self,String sql,args...)
{
    ResultStatus result=sqlite3::prepare_v2(self.db,sql.zstr_tcopy(),sql.len,&self.cmd,null);
    if(result!=sqlite3::OK)
    {
        libc::printf("failed to prepare query");
        return -1;
    }
    self.step();
    
    if(self.column_count())
    {
        return self.changes64();
    }
    return 0;
}


fn ResultStatus SqliteConnector.execute(&self,String query,ExecCallback callback=null,void* arg=null,ZString* errmsg=null)
{
    return sqlite3::exec(self.db,query.zstr_tcopy(),callback,arg,errmsg);
}

fn int SqliteConnector.exec(&self,String query,args...)
{
    ResultStatus result=sqlite3::prepare_v2(self.db,query.zstr_tcopy(),query.len,&self.cmd,null);
    if(result!=sqlite3::OK)
    {
        libc::printf("Faied to excute query");
        return -1;
    }
    self.step();
    if(self.column_count())
    {
        return self.changes64();
    }
    
    return 0;
}
fn bool SqliteConnector.step(&self)
{
    ResultStatus result=sqlite3::step(self.cmd);
    if(result==sqlite3::DONE)
    {
        sqlite3::reset(self.cmd);
        return false;
    }
    return true;
}
fn bool SqliteConnector.next(&self)
{
    return self.step();
}
fn int SqliteConnector.column_count(&self)
{
    return sqlite3::column_count(self.cmd);
}
fn int SqliteConnector.column_int(&self,int index)
{
    return sqlite3::column_int(self.cmd,index);
}

fn long SqliteConnector.column_int64(&self,int index)
{
    return sqlite3::column_int64(self.cmd,index);
}
fn long SqliteConnector.total_count(&self,String table_name="")
{
    if(!table_name.len)
    {
        return self.column_int64(0);
    }
        self.query(string::tformat("select count(*) from %s;",table_name));
        return self.column_int64(0);
   
}
fn ulong SqliteConnector.max_id(&self,String table_name="",String id="")
{
    if(!table_name.len)
    {
        return 0;
    }
    self.exec(string::tformat("select * from %s order by %s desc LIMIT 10 ;",table_name,id));
    return self.@column(0,ulong);
 
}
fn ResultStatus SqliteConnector.reset(&self)
{
    return sqlite3::reset(self.cmd);
}

fn ResultStatus SqliteConnector.finalize(&self)
{
    return sqlite3::finalize(self.cmd);
}

fn ResultStatus SqliteConnector.close(&self)
{
    return sqlite3::close(self.db);
}


  

fn String ptrtostr(char* ptr,int size=0)
{
    return ((ZString)(ptr)).str_view();
}

fn ushort[] ptrtoblob(ushort* ptr,int size)
{
    ushort[] blob;
    if(ptr!=null)
    {
        for(int i=0;i<size;i++)
        {
            blob[i]=*ptr++;
        }
    }
    return blob;
}

fn ResultStatus SqliteConnector.free(&self,char* msg)
{
    return sqlite3::free(msg);
}

macro SqliteConnector.@column(&self,int index,$Type)
{
    $switch($Type.nameof):
        $case ushort.nameof:
        $case uint.nameof:
            return sqlite3::column_int(self.cmd,index);
        $case ulong.nameof:
            return sqlite3::column_int64(self.cmd,index);
        $case float.nameof:
        $case double.nameof:
            return sqlite3::column_float(self.cmd,index);
        $case String.nameof:
            return ptrtostr((char*)sqlite3::column_text(self.cmd,index),sqlite3::column_bytes(self.cmd,index));
        $case char[].nameof:
            return (char[])ptrtostr((char*)sqlite3::column_text(self.cmd,index),sqlite3::column_bytes(self.cmd,index));
        $case ushort[].nameof:
            return ptrtoblob((ushort*)sqlite3::column_blob(self.cmd,index),sqlite3::column_bytes(self.cmd,index));
        $default:
            return sqlite3::column_value(self.cmd,index);
        $endswitch
        
}    
fn ResultStatus SqliteConnector.bindOne(&self,int index,int value)
{
    return sqlite3::bind_int(self.cmd,index,value);
}
macro SqliteConnector.@bind(&self,int index,param)
{
    $switch($typeof(param).nameof):
        $case ushort.nameof:
        $case uint.nameof:
            return sqlite3::bind_int(self.cmd,index,param);
        $case ulong.nameof:
            return sqlite3::bind_int64(self.cmd,index,param);
        $case float.nameof:
        $case double.nameof:
            return sqlit3::bind_double(self.cmd,index,param);
        $case String.nameof:
        $case char[].nameof:
            return sqltie3::bind_text(self.cmd,(char*)param,param.len,null);
        $case ushort[].nameof:
            return sqlite3::bind_bolb(self.cmd,index,(void*)param,param.len,null);
        $case int[].nameof:
            return sqlite3::bind_zeroblob(self.cmd,index,param[0]);
        $case void*.nameof:
            return sqlite3::bind_null(self.cmd,index);
        $default:
            return sqlite3::bind_value(self.cmd,index,&$param);
        $endswitch    
}

fn ulong SqliteConnector.insertId(&self)
{
    return sqlite3::last_insert_rowid(self.db);
}
fn ulong SqliteConnector.lastInsertId(&self)
{
    return self.insertId();
}
fn int SqliteConnector.changes64(&self)
{
    return sqlite3::changes64(self.db);
}

fn int SqliteConnector.changes(&self)
{
    return sqlite3::changes(self.db);
}

fn SqliteHandle SqliteConnector.getDb(&self)
{
    return self.db;
}
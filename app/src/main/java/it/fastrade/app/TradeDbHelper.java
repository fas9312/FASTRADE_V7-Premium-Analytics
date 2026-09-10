package it.fastrade.app;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import java.util.ArrayList;
import java.util.List;

public class TradeDbHelper extends SQLiteOpenHelper {
    private static final String DB_NAME = "fastrade.db";
    private static final int DB_VERSION = 3;
    public TradeDbHelper(Context context) { super(context, DB_NAME, null, DB_VERSION); }

    @Override public void onCreate(SQLiteDatabase db) {
        db.execSQL("CREATE TABLE operations (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT,"+
                "date TEXT NOT NULL,"+
                "match_name TEXT,"+
                "market TEXT NOT NULL,"+
                "minute TEXT,"+
                "tranche TEXT,"+
                "stake_pct REAL NOT NULL DEFAULT 0,"+
                "stake_eur REAL NOT NULL DEFAULT 0,"+
                "result REAL NOT NULL DEFAULT 0,"+
                "rating TEXT,"+
                "notes TEXT,"+
                "sport TEXT DEFAULT 'Calcio',"+
                "market_type TEXT DEFAULT '',"+
                "strategy TEXT DEFAULT '',"+
                "odds REAL NOT NULL DEFAULT 0)");
        createStrategiesTable(db);
    }

    private void createStrategiesTable(SQLiteDatabase db) {
        db.execSQL("CREATE TABLE IF NOT EXISTS strategies ("+
                "id INTEGER PRIMARY KEY AUTOINCREMENT,"+
                "name TEXT NOT NULL UNIQUE,"+
                "description TEXT,"+
                "default_stake_pct REAL NOT NULL DEFAULT 0,"+
                "active INTEGER NOT NULL DEFAULT 1,"+
                "custom INTEGER NOT NULL DEFAULT 1)");
    }

    @Override public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        if (oldVersion < 2) createStrategiesTable(db);
        if (oldVersion < 3) {
            try { db.execSQL("ALTER TABLE operations ADD COLUMN sport TEXT DEFAULT 'Calcio'"); } catch(Exception ignored) {}
            try { db.execSQL("ALTER TABLE operations ADD COLUMN market_type TEXT DEFAULT ''"); } catch(Exception ignored) {}
            try { db.execSQL("ALTER TABLE operations ADD COLUMN strategy TEXT DEFAULT ''"); } catch(Exception ignored) {}
            try { db.execSQL("ALTER TABLE operations ADD COLUMN odds REAL NOT NULL DEFAULT 0"); } catch(Exception ignored) {}
            db.execSQL("UPDATE operations SET strategy=market WHERE strategy IS NULL OR strategy='' ");
        }
    }

    public long addOperation(Operation op) {
        ContentValues v = new ContentValues();
        v.put("date",op.date); v.put("match_name",op.match); v.put("market",op.market);
        v.put("minute",op.minute); v.put("tranche",op.tranche); v.put("stake_pct",op.stakePct);
        v.put("stake_eur",op.stakeEur); v.put("result",op.result); v.put("rating",op.rating); v.put("notes",op.notes);
        v.put("sport",op.sport); v.put("market_type",op.marketType); v.put("strategy",op.strategy); v.put("odds",op.odds);
        return getWritableDatabase().insert("operations",null,v);
    }
    public void deleteOperation(long id){ getWritableDatabase().delete("operations","id=?",new String[]{String.valueOf(id)}); }

    public List<Operation> allOperations() {
        ArrayList<Operation> list=new ArrayList<>();
        Cursor c=getReadableDatabase().rawQuery("SELECT id,date,match_name,market,minute,tranche,stake_pct,stake_eur,result,rating,notes,sport,market_type,strategy,odds FROM operations ORDER BY id DESC",null);
        try { while(c.moveToNext()){
            Operation o=new Operation(); o.id=c.getLong(0); o.date=n(c.getString(1)); o.match=n(c.getString(2)); o.market=n(c.getString(3));
            o.minute=n(c.getString(4)); o.tranche=n(c.getString(5)); o.stakePct=c.getDouble(6); o.stakeEur=c.getDouble(7); o.result=c.getDouble(8);
            o.rating=n(c.getString(9)); o.notes=n(c.getString(10)); o.sport=n(c.getString(11)); o.marketType=n(c.getString(12)); o.strategy=n(c.getString(13)); o.odds=c.getDouble(14);
            if(o.sport.isEmpty()) o.sport="Calcio"; if(o.strategy.isEmpty()) o.strategy=o.market; if(o.marketType.isEmpty()) o.marketType=o.market;
            list.add(o);
        }} finally { c.close(); }
        return list;
    }
    private static String n(String s){ return s==null?"":s; }

    public long addStrategy(String name,String description,double defaultStakePct){ ContentValues v=new ContentValues();v.put("name",name.trim());v.put("description",description.trim());v.put("default_stake_pct",defaultStakePct);v.put("active",1);v.put("custom",1);return getWritableDatabase().insert("strategies",null,v); }
    public void updateStrategy(long id,String name,String description,double defaultStakePct,boolean active){ ContentValues v=new ContentValues();v.put("name",name.trim());v.put("description",description.trim());v.put("default_stake_pct",defaultStakePct);v.put("active",active?1:0);getWritableDatabase().update("strategies",v,"id=?",new String[]{String.valueOf(id)}); }
    public void deleteStrategy(long id){ getWritableDatabase().delete("strategies","id=?",new String[]{String.valueOf(id)}); }
    public List<Strategy> allStrategies(boolean onlyActive){ ArrayList<Strategy> list=new ArrayList<>();String sql="SELECT id,name,description,default_stake_pct,active,custom FROM strategies"+(onlyActive?" WHERE active=1":"")+" ORDER BY name COLLATE NOCASE";Cursor c=getReadableDatabase().rawQuery(sql,null);try{while(c.moveToNext()){Strategy s=new Strategy();s.id=c.getLong(0);s.name=n(c.getString(1));s.description=n(c.getString(2));s.defaultStakePct=c.getDouble(3);s.active=c.getInt(4)==1;s.custom=c.getInt(5)==1;list.add(s);}}finally{c.close();}return list; }

    public static class Operation { public long id; public String date="",match="",market="",minute="",tranche="",rating="",notes="",sport="Calcio",marketType="",strategy=""; public double stakePct,stakeEur,result,odds; }
    public static class Strategy { public long id; public String name="",description=""; public double defaultStakePct; public boolean active=true,custom=true; }
}

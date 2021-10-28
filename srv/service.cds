using { com.dk.mycapapp as mydb } from '../db/schema';

service MyCapApp {
    entity Students as projection on mydb.Students;
}
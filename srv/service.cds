using { com.dk.mycapapp as mydb } from '../db/schema';

service MyCappApp {
    entity Students as projection on mydb.Students;
}
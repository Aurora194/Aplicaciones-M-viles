import redis from "../config/redis";

export async function blacklist(token:string){

    await redis.set(

        token,

        "blacklisted",

        "EX",

        60*60*24

    );

}
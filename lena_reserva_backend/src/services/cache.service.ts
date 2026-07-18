import redis from "../config/redis";

export async function getCache(

key:string

){

    const data=await redis.get(key);

    if(!data){

        return null;

    }

    return JSON.parse(data);

}

export async function setCache(

key:string,

value:any,

ttl:number

){

    await redis.set(

        key,

        JSON.stringify(value),

        "EX",

        ttl

    );

}

export async function deleteCache(

key:string

){

    await redis.del(key);

}
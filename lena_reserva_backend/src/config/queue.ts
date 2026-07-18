import { Queue } from "bullmq";

import redis from "./redis";

export const reservationQueue = new Queue(

    "reservationQueue",

    {

        connection: redis

    }

);
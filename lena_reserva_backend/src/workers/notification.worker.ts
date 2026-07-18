import { Worker } from "bullmq";

import redis from "../config/redis";

const worker = new Worker(

    "reservationQueue",

    async job=>{

        console.log("");

        console.log("================================");

        console.log("Nueva Reserva");

        console.log(job.data);

        console.log("================================");

    },

    {

        connection:redis

    }

);

worker.on(

    "completed",

    ()=>{

        console.log("Trabajo completado");

    }

);

worker.on(

    "failed",

    ()=>{

        console.log("Error procesando trabajo");

    }

);
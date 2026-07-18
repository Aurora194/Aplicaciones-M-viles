import { reservationQueue } from "../config/queue";

export async function sendReservationNotification(

    reserva:any

){

    await reservationQueue.add(

        "reservation-created",

        reserva

    );

}
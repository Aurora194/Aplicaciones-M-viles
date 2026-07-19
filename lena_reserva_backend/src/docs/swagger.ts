import swaggerJsdoc from "swagger-jsdoc";
import swaggerUi from "swagger-ui-express";

const options: swaggerJsdoc.Options = {

    definition:{
        openapi:"3.0.0",

        info:{
            title:"Leña Reserva API",
            version:"1.0.0",
            description:"API del sistema de reservas."
        },

        servers:[
            {
                url:"http://localhost:3000"
            }
        ],

        components:{
            securitySchemes:{
                bearerAuth:{
                    type:"http",
                    scheme:"bearer",
                    bearerFormat:"JWT"
                }
            }
        }

    },

    apis:[
        "./src/routes/*.ts"
    ]

};



    export const swaggerSpec=swaggerJsdoc(options);



export {swaggerUi};
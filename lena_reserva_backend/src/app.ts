import express from "express";
import cors from "cors";
import morgan from "morgan";
import helmet from "helmet";
import compression from "compression";

import authRoutes from "./routes/auth.routes";
import userRoutes from "./routes/user.routes";
import mesaRoutes from "./routes/mesa.routes";
import reservaRoutes from "./routes/reserva.routes";

import swaggerUi from "swagger-ui-express";
import { swaggerSpec } from "./docs/swagger";

import { limiter } from "./middleware/rateLimit.middleware";



const app = express();


app.get("/", (req, res) => {
    res.json({
        success: true,
        message: "🚀 Bienvenido a Leña Reserva API",
        version: "1.0.0",
        docs: "http://localhost:3000/api/docs",
        health: "http://localhost:3000/api/health"
    });
});

app.use(cors());

app.use(helmet()); 

app.use(compression());

app.use(express.json());

app.use(limiter);

app.use(morgan('dev'));

app.use("/api/auth", authRoutes);

app.use("/api/users", userRoutes);

app.get('/api/health', (req, res) => {

    res.status(200).json({

        success: true,

        message: 'Leña Reserva API funcionando correctamente'

    });

});

app.use("/api/mesas", mesaRoutes);

app.use("/api/reservas",reservaRoutes);

app.use(

    "/api/docs",

    swaggerUi.serve,

    swaggerUi.setup(swaggerSpec)

);


export default app;
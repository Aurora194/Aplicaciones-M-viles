export function success(

    data:any,

    message="Proceso realizado correctamente."

){

    return{

        success:true,

        message,

        data

    };

}

export function error(

    message:string

){

    return{

        success:false,

        message

    };

}
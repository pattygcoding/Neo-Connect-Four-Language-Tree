/** @type {import('tailwindcss').Config} */
export default {
    content: ["./index.html", "./src/**/*.js"],
    theme: {
        extend: {
            colors: {
                mint: {
                    400: "#5eead4",
                },
            },
        },
    },
    plugins: [],
};

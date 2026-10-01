export const metadata = {
    title: "Connect Four",
    description: "Connect Four built with Next.js",
};

export default function RootLayout({ children }) {
    return (
        <html lang="en">
            <body>{children}</body>
        </html>
    );
}

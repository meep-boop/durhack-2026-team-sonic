import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Viewport } from "./scene/Viewport.tsx";
import "./styles.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <Viewport />
  </StrictMode>,
);

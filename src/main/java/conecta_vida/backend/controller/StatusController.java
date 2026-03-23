package conecta_vida.backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class StatusController {

    @GetMapping("/status")
    public String checkStatus() {
        return "🟢 API do Conecta Vida está online e rodando!";
    }
}
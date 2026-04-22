use std::sync::{Arc, Mutex};


pub struct Application {
    #[allow(unused)]
    name: String,
    alive: Arc<Mutex<bool>>,
}

impl Application {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            alive: Arc::new(Mutex::new(true)),
        }
    }

    pub fn main_loop(self) {
        let mut current_status = true;
        while current_status {
            

            let alive_guard = self.alive.lock().unwrap();
            current_status = *alive_guard;
        }
    }
}
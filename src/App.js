import "./App.css";
import Bulletin from "./components/Bulletin";
import Navbar from "./components/Navbar";

function App() {
  return (
    <div className="app">
      <Navbar />
      <Bulletin />
    </div>
  );
}

export default App;
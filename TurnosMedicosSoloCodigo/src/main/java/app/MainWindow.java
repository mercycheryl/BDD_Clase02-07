package app;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.sql.*;

public class MainWindow extends JFrame {
    private JPanel panel;
    private JButton btnRegistrarPaciente;
    private JButton btnVerTurnos;
    private JTextField txtNombre;
    private JTextField txtCedula;
    private JTextField txtFechaNacimiento;
    private JTextArea txtResultados;

    public MainWindow() {
        setTitle("Sistema de Turnos Médicos");
        setSize(600, 400);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setLocationRelativeTo(null);

        panel = new JPanel();
        panel.setLayout(null);

        JLabel lblNombre = new JLabel("Nombre:");
        lblNombre.setBounds(30, 20, 100, 25);
        panel.add(lblNombre);

        txtNombre = new JTextField();
        txtNombre.setBounds(140, 20, 200, 25);
        panel.add(txtNombre);

        JLabel lblCedula = new JLabel("Cédula:");
        lblCedula.setBounds(30, 60, 100, 25);
        panel.add(lblCedula);

        txtCedula = new JTextField();
        txtCedula.setBounds(140, 60, 200, 25);
        panel.add(txtCedula);

        JLabel lblFecha = new JLabel("Fecha Nac (YYYY-MM-DD):");
        lblFecha.setBounds(30, 100, 200, 25);
        panel.add(lblFecha);

        txtFechaNacimiento = new JTextField();
        txtFechaNacimiento.setBounds(240, 100, 100, 25);
        panel.add(txtFechaNacimiento);

        btnRegistrarPaciente = new JButton("Registrar Paciente");
        btnRegistrarPaciente.setBounds(30, 150, 180, 30);
        panel.add(btnRegistrarPaciente);

        btnVerTurnos = new JButton("Ver Turnos Activos");
        btnVerTurnos.setBounds(220, 150, 180, 30);
        panel.add(btnVerTurnos);

        //:::::::::::::::::::::::::::
        JButton btnCalcularEdad = new JButton("Calcular Edad"); // ✅ Botón nuevo
        btnCalcularEdad.setBounds(410, 150, 150, 30);
        panel.add(btnCalcularEdad);
        //:::::::::::::::::::
        txtResultados = new JTextArea();
        txtResultados.setEditable(false);
        JScrollPane scroll = new JScrollPane(txtResultados);
        scroll.setBounds(30, 200, 520, 130);
        panel.add(scroll);

        setContentPane(panel);
        setVisible(true);

        btnRegistrarPaciente.addActionListener(e -> registrarPaciente());
        btnVerTurnos.addActionListener(e -> mostrarTurnos());
        //
        btnCalcularEdad.addActionListener(e -> calcularEdad());
    }

    private void calcularEdad() {
        try (Connection conn = DBConnection.getConnection()) {
            String fechaNac = txtFechaNacimiento.getText();

            String query = "SELECT obtener_edad(?)";
            PreparedStatement stmt = conn.prepareStatement(query);
            stmt.setString(1, fechaNac);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                int edad = rs.getInt(1);
                txtResultados.setText("Edad del paciente: " + edad + " años");
            } else {
                txtResultados.setText("No se pudo calcular la edad.");
            }
        } catch (SQLException ex) {
            txtResultados.setText("Error al calcular edad: " + ex.getMessage());
        }
    }

    private void registrarPaciente() {
        try (Connection conn = DBConnection.getConnection()) {
            String nombre = txtNombre.getText();
            String cedula = txtCedula.getText();
            String fecha = txtFechaNacimiento.getText();

            CallableStatement stmt = conn.prepareCall("{CALL registrar_paciente(?, ?, ?)}");
            stmt.setString(1, nombre);
            stmt.setString(2, cedula);
            stmt.setString(3, fecha);
            stmt.execute();
            txtResultados.setText("Paciente registrado correctamente.");
        } catch (SQLException ex) {
            txtResultados.setText("Error: " + ex.getMessage());
        }
    }

    private void mostrarTurnos() {
        try (Connection conn = DBConnection.getConnection()) {
            String query = "SELECT * FROM vista_turnos_activos";
            PreparedStatement stmt = conn.prepareStatement(query);
            ResultSet rs = stmt.executeQuery();
            StringBuilder sb = new StringBuilder();
            while (rs.next()) {
                sb.append("ID: ").append(rs.getInt("id")).append(" - ")
                  .append("Paciente: ").append(rs.getString("paciente")).append(" - ")
                  .append("Médico: ").append(rs.getString("medico")).append(" - ")
                  .append("Fecha: ").append(rs.getDate("fecha")).append("\n");
            }
            txtResultados.setText(sb.toString());
        } catch (SQLException ex) {
            txtResultados.setText("Error: " + ex.getMessage());
        }
    }

    public static void main(String[] args) {
        new MainWindow();
    }
}
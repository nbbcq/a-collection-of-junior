import java.io.*;
import java.util.*;

class EmployeeExtern {
    int id;
    String name;
    int age;
    int salary;
    String hireDay;
    String department;
    public EmployeeExtern() {}

    EmployeeExtern(int id, String name, int age, int salary, String hireDay, String department) {
        this.id = id;
        this.name = name;
        this.age = age;
        this.salary = salary;
        this.hireDay = hireDay;
        this.department = department;
    }

    public String toString() {
        return "id: " + id + "\nname: " + name + "\nage: " + age +
            "\nsalary: " + salary + "\nhireDay: " + hireDay + "\ndepartment: " + department;
    }
}

class ManagerExtern extends EmployeeExtern implements Externalizable {
    String position;
    public ManagerExtern() {}
    ManagerExtern(int id, String name, int age, int salary, String hireDay, String department, String position){
        super(id, name, age, salary, hireDay, department);
        this.position = position;
    }

    public void writeExternal(ObjectOutput out) throws IOException {
        Date savedDate = new Date();
        out.writeInt(id);
        out.writeInt(age);
        out.writeObject(name);
        out.writeInt(salary);
        out.writeObject(hireDay);
        out.writeObject(department);
        out.writeObject(position);
        out.writeInt(savedDate.getYear());
    }

    public void readExternal(ObjectInput in) throws IOException,
           java.lang.ClassNotFoundException {
               Date readDate = new Date();
               int savedYear;
               id = in.readInt();
               age = in.readInt();
               name = (String)in.readObject();
               salary = in.readInt();
               hireDay = (String)in.readObject();
               department = (String)in.readObject();
               position = (String)in.readObject();
               savedYear = in.readInt();
               age = age + (readDate.getYear() - savedYear);
    }

    public String toString() {
        return super.toString() + "\nposition: " + position;
    }
}

public class ObjectTest {
    public static void main(String[] args) {
        ManagerExtern manager = new ManagerExtern(456789, "Jack", 40, 10000, "80/10/10", "intel", "teamleader");
        try {
            ObjectOutputStream fout = new ObjectOutputStream(
                    new FileOutputStream("/tmp/data2.ser"));
            fout.writeObject(manager);
            fout.close();
        } catch(Exception e) {
            System.out.println(e);
        }
        manager = null;
        try {
            ObjectInputStream fin = new ObjectInputStream(
                    new FileInputStream("/tmp/data2.ser"));
            manager = (ManagerExtern)fin.readObject();
        } catch(Exception e) {
            System.out.println(e);
        }
        System.out.println("manager " + manager.toString());
    }
}

module compound_datatype2;

/************************************************************

  This example shows how to read and write a complex
  compound datatype to a dataset.  The program first writes
  complex compound structures to a dataset with a dataspace
  of DIM0, then closes the file.  Next, it reopens the file,
  reads back selected fields in the structure, and outputs
  them to the screen.

  Unlike the other datatype examples, in this example we
  save to the file using native datatypes to simplify the
  type definitions here.  To save using standard types you
  must manually calculate the sizes and offsets of compound
  types as shown in h5ex_t_cmpd.c, and convert enumerated
  values as shown in h5ex_t_enum.c.

  The datatype defined here consists of a compound
  containing a variable-length list of compound types, as
  well as a variable-length string, enumeration, double
  array, object reference and region reference.  The nested
  compound type contains an int, variable-length string and
  two doubles.

  This file is intended for use with HDF5 Library version 1.6

 ************************************************************/

import std.stdio: writef;
import core.memory: GC;

import hdf5.hdf5;

enum FILE    = "h5ex_t_cpxcmpd.h5";
enum DATASET = "DS1";
enum DIM0    = 2;

struct sensor_t {
    int     serial_no;
    string  location;
    double  temperature;
    double  pressure;
};                                 /* Nested compound type */

enum color_t {
    RED,
    GREEN,
    BLUE
};                                /* Enumerated type */

struct vehicle_t {
    hvl_t               sensors;
    string              name;
    color_t             color;
    double[3]           location;
    hobj_ref_t          group;
    hdset_reg_ref_t     surveyed_areas;
};                                /* Main compound type */

struct rvehicle_t {
    hvl_t     sensors;
    string    name;
    color_t   color;
    double[3] location;
};                               /* Read type */

void
main()
{
    hid_t          file, vehicletype, colortype, sensortype, sensorstype, loctype,
                   strtype, rvehicletype, rsensortype, rsensorstype, space, dset,
                   group;
                                            /* Handles */
    herr_t         status;
    hsize_t[1]     dims   = [ DIM0 ];
    hsize_t[1]     adims  = [ 3 ];
    hsize_t[2]     adims2 = [ 32, 32 ];
    hsize_t[2]     start  = [ 8, 26 ];
    hsize_t[2]     count  = [ 4, 3 ];
    hsize_t[2][3]  coords = [ [ 3, 2 ],
                              [ 3, 3 ],
                              [ 4, 4 ] ];
    vehicle_t[2]   wdata;                   /* Write buffer */
    rvehicle_t     *rdata;                  /* Read buffer */
    color_t        val;
    sensor_t       *ptr;
    double[32][32] wdata2;
    int            ndims;

    /*
     * Create a new file using the default properties.
     */
    file = H5Fcreate (FILE, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);

    /*
     * Create dataset to use for region references.
     */
    foreach (i; 0..32)
        foreach (j; 0..32)
            wdata2[i][j]= 70. + 0.1 * (i - 16.) + 0.1 * (j - 16.);
    space = H5Screate_simple (2, adims2.ptr, null);
    dset = H5Dcreate2 (file, "Ambient_Temperature", H5T_NATIVE_DOUBLE, space,
                H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    status = H5Dwrite (dset, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT,
                wdata2[0].ptr);
    status = H5Dclose (dset);

    /*
     * Create groups to use for object references.
     */
    group = H5Gcreate2 (file, "Land_Vehicles", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    status = H5Gclose (group);
    group = H5Gcreate2 (file, "Air_Vehicles", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    status = H5Gclose (group);

    /*
     * Initialize variable-length compound in the first data element.
     */
    wdata[0].sensors.len = 4;
    ptr = cast(sensor_t *) GC.malloc (wdata[0].sensors.len * sensor_t.sizeof);
    ptr[0].serial_no = 1153;
    ptr[0].location = "Exterior (static)";
    ptr[0].temperature = 53.23;
    ptr[0].pressure = 24.57;
    ptr[1].serial_no = 1184;
    ptr[1].location = "Intake";
    ptr[1].temperature = 55.12;
    ptr[1].pressure = 22.95;
    ptr[2].serial_no = 1027;
    ptr[2].location = "Intake manifold";
    ptr[2].temperature = 103.55;
    ptr[2].pressure = 31.23;
    ptr[3].serial_no = 1313;
    ptr[3].location = "Exhaust manifold";
    ptr[3].temperature = 1252.89;
    ptr[3].pressure = 84.11;
    wdata[0].sensors.p = cast(void *) ptr;

    /*
     * Initialize other fields in the first data element.
     */
    wdata[0].name = "Airplane";
    wdata[0].color = color_t.GREEN;
    wdata[0].location[0] = -103234.21;
    wdata[0].location[1] = 422638.78;
    wdata[0].location[2] = 5996.43;
    status = H5Rcreate (&wdata[0].group, file, "Air_Vehicles", H5R_type_t.H5R_OBJECT, -1);
    status = H5Sselect_elements (space, H5S_seloper_t.H5S_SELECT_SET, 3, coords[0].ptr);
    status = H5Rcreate (&wdata[0].surveyed_areas, file, "Ambient_Temperature",
                H5R_type_t.H5R_DATASET_REGION, space);

    /*
     * Initialize variable-length compound in the second data element.
     */
    wdata[1].sensors.len = 1;
    ptr = cast(sensor_t *) GC.malloc (wdata[1].sensors.len * sensor_t.sizeof);
    ptr[0].serial_no = 3244;
    ptr[0].location = "Roof";
    ptr[0].temperature = 83.82;
    ptr[0].pressure = 29.92;
    wdata[1].sensors.p = cast(void *) ptr;

    /*
     * Initialize other fields in the second data element.
     */
    wdata[1].name = "Automobile";
    wdata[1].color = color_t.RED;
    wdata[1].location[0] = 326734.36;
    wdata[1].location[1] = 221568.23;
    wdata[1].location[2] = 432.36;
    status = H5Rcreate (&wdata[1].group, file, "Land_Vehicles", H5R_type_t.H5R_OBJECT, -1);
    status = H5Sselect_hyperslab (space, H5S_seloper_t.H5S_SELECT_SET, start.ptr, null, count.ptr,
                null);
    status = H5Rcreate (&wdata[1].surveyed_areas, file, "Ambient_Temperature",
                H5R_type_t.H5R_DATASET_REGION, space);

    status = H5Sclose (space);

    /*
     * Create variable-length datatype compatible with D string.
     */
    strtype = H5Tvlen_create (H5T_NATIVE_B8);
    assert(strtype >= 0);

    /*
     * Create the nested compound datatype.
     */
    sensortype = H5Tcreate (H5T_class_t.H5T_COMPOUND, sensor_t.sizeof);
    status = H5Tinsert (sensortype, "Serial number",
                sensor_t.serial_no.offsetof, H5T_NATIVE_INT);
    status = H5Tinsert (sensortype, "Location", 
                sensor_t.location.offsetof, strtype);
    status = H5Tinsert (sensortype, "Temperature (F)",
                sensor_t.temperature.offsetof, H5T_NATIVE_DOUBLE);
    status = H5Tinsert (sensortype, "Pressure (inHg)",
                sensor_t.pressure.offsetof, H5T_NATIVE_DOUBLE);

    /*
     * Create the variable-length datatype.
     */
    sensorstype = H5Tvlen_create (sensortype);
    assert(sensorstype >= 0);

    /*
     * Create the enumerated datatype.
     */
    colortype = H5Tenum_create (H5T_NATIVE_INT);
    val = color_t.RED;
    status = H5Tenum_insert (colortype, "Red", &val);
    val = color_t.GREEN;
    status = H5Tenum_insert (colortype, "Green", &val);
    val = color_t.BLUE;
    status = H5Tenum_insert (colortype, "Blue", &val);

    /*
     * Create the array datatype.
     */
    loctype = H5Tarray_create2 (H5T_NATIVE_DOUBLE, 1U, adims.ptr);

    /*
     * Create the main compound datatype.
     */
    vehicletype = H5Tcreate (H5T_class_t.H5T_COMPOUND, vehicle_t.sizeof);
    status = H5Tinsert (vehicletype, "Sensors", vehicle_t.sensors.offsetof,
                sensorstype);
    status = H5Tinsert (vehicletype, "Name", vehicle_t.name.offsetof,
                strtype);
    status = H5Tinsert (vehicletype, "Color", vehicle_t.color.offsetof,
                colortype);
    status = H5Tinsert (vehicletype, "Location", vehicle_t.location.offsetof,
                loctype);
    status = H5Tinsert (vehicletype, "Group", vehicle_t.group.offsetof,
                H5T_STD_REF_OBJ);
    status = H5Tinsert (vehicletype, "Surveyed areas",
                vehicle_t.surveyed_areas.offsetof, H5T_STD_REF_DSETREG);

    /*
     * Create dataspace.  Setting maximum size to null sets the maximum
     * size to be the current size.
     */
    space = H5Screate_simple (1, dims.ptr, null);

    /*
     * Create the dataset and write the compound data to it.
     */
    dset = H5Dcreate2 (file, DATASET, vehicletype, space, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    assert(dset >= 0);
    status = H5Dwrite (dset, vehicletype, H5S_ALL, H5S_ALL, H5P_DEFAULT, wdata.ptr);

    /*
     * Close and release resources.  Note that we cannot use
     * H5Dvlen_reclaim as it would attempt to free() the string
     * constants used to initialize the name fields in wdata.  We must
     * therefore manually free() only the data previously allocated
     * through malloc().
     */
    foreach (i; 0..dims[0])
        GC.free (wdata[i].sensors.p);
    status = H5Dclose (dset);
    status = H5Sclose (space);
    status = H5Tclose (strtype);
    status = H5Tclose (sensortype);
    status = H5Tclose (sensorstype);
    status = H5Tclose (colortype);
    status = H5Tclose (loctype);
    status = H5Tclose (vehicletype);
    status = H5Fclose (file);


    /*
     * Now we begin the read section of this example.  Here we assume
     * the dataset has the same name and rank, but can have any size.
     * Therefore we must allocate a new array to read in data using
     * malloc().  We will only read back the variable length strings.
     */

    /*
     * Open file and dataset.
     */
    file = H5Fopen (FILE, H5F_ACC_RDONLY, H5P_DEFAULT);
    dset = H5Dopen2 (file, DATASET, H5P_DEFAULT);

    /*
     * Create variable-length datatype compatible with D string.
     */
    auto rstrtype = H5Tvlen_create (H5T_NATIVE_B8);
    assert(rstrtype >= 0);

    /*
     * Create the enumerated datatype.
     */
    auto rcolortype = H5Tenum_create (H5T_NATIVE_INT);
    auto val2 = color_t.RED;
    status = H5Tenum_insert (rcolortype, "Red", &val2);
    val2 = color_t.GREEN;
    status = H5Tenum_insert (rcolortype, "Green", &val2);
    val2 = color_t.BLUE;
    status = H5Tenum_insert (rcolortype, "Blue", &val2);

    auto rloctype = H5Tarray_create2 (H5T_NATIVE_DOUBLE, 1U, adims.ptr);

    /*
     * Create the nested compound datatype for reading.  Even though it
     * has only one field, it must still be defined as a compound type
     * so the library can match the correct field in the file type.
     * This matching is done by name.  However, we do not need to
     * define a structure for the read buffer as we can simply treat it
     * as a char *.
     */
    rsensortype = H5Tcreate (H5T_class_t.H5T_COMPOUND,  sensor_t.sizeof);
    status = H5Tinsert (rsensortype, "Location",        sensor_t.location.offsetof,    rstrtype);
    status = H5Tinsert (rsensortype, "Serial number",   sensor_t.serial_no.offsetof,   H5T_NATIVE_INT);
    status = H5Tinsert (rsensortype, "Temperature (F)", sensor_t.temperature.offsetof, H5T_NATIVE_DOUBLE);
    status = H5Tinsert (rsensortype, "Pressure (inHg)", sensor_t.pressure.offsetof,    H5T_NATIVE_DOUBLE);
    
    /*
     * Create the variable-length datatype for reading.
     */
    rsensorstype = H5Tvlen_create (rsensortype);
    assert(rsensorstype >= 0);

    /*
     * Create the main compound datatype for reading.
     */
    rvehicletype = H5Tcreate (H5T_class_t.H5T_COMPOUND, rvehicle_t.sizeof);
    status = H5Tinsert (rvehicletype, "Sensors", rvehicle_t.sensors.offsetof,
                rsensorstype);
    status = H5Tinsert (rvehicletype, "Name", rvehicle_t.name.offsetof,
                rstrtype);
    status = H5Tinsert (rvehicletype, "Color", rvehicle_t.color.offsetof,
                rcolortype);
    status = H5Tinsert (rvehicletype, "Location", rvehicle_t.location.offsetof,
                rloctype);

    /*
     * Get dataspace and allocate memory for read buffer.
     */
    space = H5Dget_space (dset);
    ndims = H5Sget_simple_extent_dims (space, dims.ptr, null);
    rdata = cast(rvehicle_t *) GC.malloc (dims[0] * rvehicle_t.sizeof);

    /*
     * Read the data.
     */
    status = H5Dread (dset, rvehicletype, H5S_ALL, H5S_ALL, H5P_DEFAULT, rdata);

    /*
     * Output the data to the screen.
     */
    foreach (i; 0..dims[0]) {
        writef ("%s[%d]:\n", DATASET, i);
        writef("%s\n", rdata[i].color);
        writef("%s\n", rdata[i].name);
        writef ("Sensor locations : %s\n", rdata[i].location);
        writef ("   Sensor data : \n");
        foreach (j; 0..rdata[i].sensors.len)
        {
            writef ("      %s\n", (cast(sensor_t*)rdata[i].sensors.p)[j] );
        }
    }

    /*
     * Close and release resources.  H5Dvlen_reclaim will automatically
     * traverse the structure and free any vlen data (including
     * strings).
     */
    status = H5Dvlen_reclaim (rvehicletype, space, H5P_DEFAULT, rdata);
    GC.free (rdata);
    status = H5Dclose (dset);
    status = H5Sclose (space);
    status = H5Tclose (rcolortype);
    status = H5Tclose (rstrtype);
    status = H5Tclose (rloctype);
    status = H5Tclose (rsensortype);
    status = H5Tclose (rsensorstype);
    status = H5Tclose (rvehicletype);
    status = H5Fclose (file);
}
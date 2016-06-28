package net.beezwax.droidfm.droidfm;

import android.app.Fragment;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.graphics.drawable.RoundedBitmapDrawable;
import android.support.v4.graphics.drawable.RoundedBitmapDrawableFactory;
import android.support.v4.widget.SwipeRefreshLayout;
import android.util.Base64;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.ListView;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import org.xmlpull.v1.XmlPullParserFactory;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.io.InputStream;

/**
 * Created by mlmartinez85 on 1/15/16.
 */
public class DroidFMListView extends Fragment {

    private static final String ns = null;
    private static String loginPassword = "username" + ":" + "password";
    private static String myHost = "https://myHost.net";
    private static String urlString = myHost + "/fmi/xml/fmresultset.xml?-db=swiftfm&-lay=person&-findall";

    private XmlPullParserFactory xmlFactoryObject;
    private FMParseTask fmParser;
    private ArrayList<Person> people;
    private PeopleAdapter adapter;
    private SwipeRefreshLayout swipeContainer;

    private View view;
    private ListView listView;

    // fragment needs empty constructor
    public DroidFMListView() {}

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        // Get ListView object from xml
        view = inflater.inflate(R.layout.list, container, false);
        listView = (ListView) view.findViewById(R.id.listview);

        // construct the data source on a background thread
        fmParser = new FMParseTask();
        // start the new thread and invoke doInBackground
        fmParser.execute(urlString);

        swipeContainer = (SwipeRefreshLayout) view.findViewById(R.id.swipeContainer);
        // setup the refresh listener for "pull-to-refresh" action
        swipeContainer.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {
            @Override
            public void onRefresh() {
                adapter.clear();
                FMParseTask fmUpdated = new FMParseTask();
                fmUpdated.execute(urlString);
                swipeContainer.setRefreshing(false);
            }
        });

        // configure the refreshing colors
        swipeContainer.setColorSchemeResources(android.R.color.holo_blue_bright,
                android.R.color.holo_green_light,
                android.R.color.holo_orange_light,
                android.R.color.holo_red_light);

        return view;
    }



    /** ArrayAdapter class to bind data to rows
    */
    public class PeopleAdapter extends ArrayAdapter<Person> {
        ViewHolder holder = null;

        public class ViewHolder {
            ImageView Image;
            TextView TextViewName;
            TextView TextViewEmail;

            public ViewHolder() {
                this.Image = null;
                this.TextViewName = null;
                this.TextViewEmail = null;
            }
        }

        public PeopleAdapter(Context context, ArrayList<Person> people) {
            super(context, 0, people);
        }

        // inflate new view and return it
        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            // get data item for this position
            Person person = getItem(position);

            // check if an existing view is being used, otherwise inflate the view
            if (convertView == null) {
                convertView = LayoutInflater.from(getContext()).inflate(R.layout.row, parent, false);
                holder = new ViewHolder();
                holder.Image = (ImageView) convertView.findViewById(R.id.photo);
                holder.TextViewName = (TextView) convertView.findViewById(R.id.name);
                holder.TextViewEmail = (TextView) convertView.findViewById(R.id.email);
            }

            // populate data into the template view using the data object
            holder.TextViewName.setText(person.name);
            holder.TextViewEmail.setText(person.email);
            if (person.photo != null) {
                new DownloadImageTask(holder.Image).execute(person.photo);
            }

            return convertView;
        }
    }



    /** ASYNC class to call URL and load images */
    private class DownloadImageTask extends AsyncTask<String, Void, Bitmap> {
        ImageView bmImage;

        public DownloadImageTask(ImageView bmImage) {
            this.bmImage = bmImage;
        }

        protected Bitmap doInBackground(String... urls) {
            String imageURL = myHost + urls[0];
            Bitmap image = null;
            Bitmap scaled = null;
            try {
                byte[] data = loginPassword.getBytes("UTF-8");
                String encoded = Base64.encodeToString(data, Base64.URL_SAFE);

                URL url = new URL(imageURL);
                HttpURLConnection conn = (HttpURLConnection)url.openConnection();
                conn.setRequestProperty("Authorization", "Basic " + encoded);

                conn.setReadTimeout(10000 /* milliseconds */);
                conn.setConnectTimeout(15000 /* milliseconds */);
                conn.setRequestMethod("GET");
                conn.connect();

                InputStream in = conn.getInputStream();
                image = BitmapFactory.decodeStream(in);

                int height = image.getHeight();
                int width = image.getWidth();

                if ( height > 1280 && width > 960 ) {
                    BitmapFactory.Options options = new BitmapFactory.Options();
                    options.inSampleSize = 4;
                    options.inJustDecodeBounds = false;

                    in.close();
                    in = conn.getInputStream();

                    scaled = BitmapFactory.decodeStream(in, null, options);
                }
                else {
                    scaled = image;
                }
            } catch (Exception e) {
                Log.e("Error", e.getMessage());
                e.printStackTrace();
            }

            return image;
        }

        protected void onPostExecute(Bitmap result) {
            RoundedBitmapDrawable drawable = RoundedBitmapDrawableFactory.create(getResources(), result);
            drawable.setCircular(true);
            bmImage.setImageDrawable(drawable);
        }
    }


    class FMParseTask extends AsyncTask<String, Integer, ArrayList<Person>> {
        /** The steps in this method will run in a separate (non-UI) thread */
        @Override
        protected ArrayList<Person> doInBackground(String... urlStrings) {

            String urlString = urlStrings[0];

            try {
                byte[] data = loginPassword.getBytes("UTF-8");
                String encoded = Base64.encodeToString(data, Base64.URL_SAFE);

                URL url = new URL(urlString);
                HttpURLConnection conn = (HttpURLConnection)url.openConnection();
                conn.setRequestProperty("Authorization", "Basic " + encoded);

                conn.setReadTimeout(10000 /* milliseconds */);
                conn.setConnectTimeout(15000 /* milliseconds */);
                conn.setRequestMethod("GET");
                conn.connect();

                InputStream stream = conn.getInputStream();
                xmlFactoryObject = XmlPullParserFactory.newInstance();
                XmlPullParser myparser = xmlFactoryObject.newPullParser();

                myparser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
                myparser.setInput(stream, null);

                parse(myparser);
                stream.close();
            } catch (Exception e) {
                e.printStackTrace();
            }

            return people;
        }

        /** This method will be called when doInBackground completes
         *  The parameter is populated from the return values of doInBackground
         *  This method runs on the UI thread, and therefore can update the UI components */
        @Override
        protected void onPostExecute(ArrayList<Person> people) {
            if (people == null) {
                return;
            }

            super.onPostExecute(people);

            // create the adapter to convert the array to views
            adapter = new PeopleAdapter(view.getContext(), people);

            // attach the adapter to the list view
            listView.setAdapter(adapter);
        }
    }

    public void parse(XmlPullParser parser) {
        try {
            parser.nextTag();
            readFMResultSet(parser);
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void readFMResultSet(XmlPullParser parser) throws XmlPullParserException, IOException {
        parser.require(XmlPullParser.START_TAG, ns, "fmresultset");
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) {
                continue;
            }

            // Starts by looking for the resultset tag
            String name = parser.getName();
            if (name.equals("resultset")) {
                readResultSet(parser);
            } else {
                skip(parser);
            }
        }
    }

    private void readResultSet(XmlPullParser parser) throws XmlPullParserException, IOException {
        people = new ArrayList();

        parser.require(XmlPullParser.START_TAG, ns, "resultset");
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) {
                continue;
            }

            // Starts by looking for the record tag
            String name = parser.getName();
            if (name.equals("record")) {
                people.add(readRecord(parser));
            } else {
                skip(parser);
            }
        }
    }

    // Parses the contents of a record. If it encounters a name, email, or photo field tag,
    // hands them off to the "read" method for processing. Otherwise, it skips the tag.
    private Person readRecord(XmlPullParser parser) throws XmlPullParserException, IOException {
        parser.require(XmlPullParser.START_TAG, ns, "record");
        String personName = null;
        String personEmail = null;
        String personPhoto = null;
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) {
                continue;
            }
            String tag = parser.getName();
            if (tag.equals("field")) {
                parser.require(XmlPullParser.START_TAG, ns, "field");
                String fieldName = parser.getAttributeValue(null, "name");

                // assign appropriate variables
                if (fieldName.equals("name")) {
                    personName = readData(parser);
                } else if (fieldName.equals("email")) {
                    personEmail = readData(parser);
                } else if (fieldName.equals("photo")) {
                    personPhoto = readData(parser);
                } else {
                    skip(parser);
                }

                parser.require(XmlPullParser.END_TAG, ns, "field");
            }
            else {
                skip(parser);
            }
        }
        return new Person(personName, personEmail, personPhoto);
    }

    // Read data in fields
    private String readData(XmlPullParser parser) throws IOException, XmlPullParserException {
        // skip over to the next tag to extract the value inside data tag
        parser.nextTag();
        // read the data and return it
        parser.require(XmlPullParser.START_TAG, ns, "data");
        String data = readText(parser);
        parser.require(XmlPullParser.END_TAG, ns, "data");
        parser.nextTag();
        return data;
    }

    private void skip(XmlPullParser parser) throws XmlPullParserException, IOException {
        if (parser.getEventType() != XmlPullParser.START_TAG) {
            throw new IllegalStateException();
        }
        int depth = 1;
        while (depth != 0) {
            switch (parser.next()) {
                case XmlPullParser.END_TAG:
                    depth--;
                    break;
                case XmlPullParser.START_TAG:
                    depth++;
                    break;
            }
        }
    }

    // Extracts text values of the tags
    private String readText(XmlPullParser parser) throws IOException, XmlPullParserException {
        String result = "";
        if (parser.next() == XmlPullParser.TEXT) {
            result = parser.getText();
            parser.nextTag();
        }
        return result;
    }
}